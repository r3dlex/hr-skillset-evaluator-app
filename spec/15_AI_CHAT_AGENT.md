# 15 — AI Chat Agent

## Overview

Domain-specific AI chat agent for the SkillForge. Provides skill evaluation guidance, AEC (Architecture/Engineering/Construction) terminology help, and data-driven insights scoped to the user's role. Supports three languages: English, German, and Chinese (EN/DE/ZH).

The chat is optional -- it requires an `ANTHROPIC_API_KEY` environment variable. Without it, the chat FAB appears but shows a "not configured" message.

## Architecture

### Provider Abstraction

```
lib/skillset_evaluator/llm/
  client.ex            # Provider-agnostic interface
  anthropic_client.ex  # Anthropic Claude API (primary)
  minimax_client.ex    # MiniMax API (optional, Chinese fallback)
  context_builder.ex   # Assembles system prompt from user/role data
  guardrails.ex        # Input/output validation
  rate_limiter.ex      # ETS-based per-user rate limiting
```

The `LLM.Client` module dispatches to the configured provider based on the `LLM_PROVIDER` env var:
- `anthropic` (default) -- Claude API
- `minimax` -- MiniMax API for Chinese-language environments
- `auto` -- Anthropic primary, MiniMax fallback if Anthropic is unreachable

### Request Flow

```
ChatInput.vue → sendMessage()
  → POST /api/chat/conversations/:id/messages
  → ChatController.create_message/2
  → LLM.ContextBuilder.build/2      (system prompt assembly)
  → LLM.Guardrails.validate_input/1 (input checks)
  → LLM.RateLimiter.check/1         (per-user rate check)
  → LLM.Client.stream/2             (Anthropic API call)
  → SSE stream chunks back to client
  → LLM.Guardrails.validate_output/1 (output checks)
  → Chat.save_message/2             (persist assistant response)
```

## Data Model

### chat_conversations

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| user_id | integer | FK to users |
| title | string | Auto-generated from first message |
| inserted_at | utc_datetime | |
| updated_at | utc_datetime | |

### chat_messages

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| conversation_id | integer | FK to chat_conversations |
| role | string | "user" or "assistant" |
| content | text | Message body (markdown) |
| token_count | integer | Approximate token usage |
| inserted_at | utc_datetime | |

### glossary_terms

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| term_en | string | English term |
| term_de | string | German term |
| term_zh | string | Chinese term |
| definition_en | text | English definition |
| definition_de | text | German definition |
| definition_zh | text | Chinese definition |
| category | string | AEC subdomain (structural, MEP, BIM, etc.) |
| inserted_at | utc_datetime | |

## System Prompt Assembly

The context builder constructs a 4-layer system prompt:

### Layer 1: Identity

```
You are an AI assistant for the SkillForge at RIB Software.
You help with skill evaluation guidance, AEC terminology, and team
development insights. You respond in the user's language (EN/DE/ZH).
```

### Layer 2: Glossary Context

Injects relevant AEC glossary terms based on detected language and conversation topic. Up to 25 terms per request to stay within token budget.

### Layer 3: User Context (role-scoped)

| Role | Context Included |
|------|-----------------|
| Admin | All teams, all users, org-wide aggregates, all evaluations |
| Manager | Own team(s), team members, team evaluations, team averages |
| User | Own evaluations, own self-scores, own gap analysis |

The context builder queries Ecto and formats data as structured text. For managers with 30+ members, aggregates are summarized rather than listed individually.

Token budget: ~4,000 tokens for user context.

### Layer 4: Conversation History

Last N messages from the current conversation, truncated to fit within the model's context window. Older messages are summarized.

## Role-Based Data Scoping

All data access in the context builder respects role boundaries:

- **Admin**: `Evaluations.list_all/1`, `Teams.list_all/0`, full cross-team visibility
- **Manager**: `Evaluations.list_for_teams/2`, `Teams.list_for_manager/1`, own teams only
- **User**: `Evaluations.list_for_user/2`, own data only

The LLM never receives data the user cannot access through the UI. This is enforced at the context builder level, not at the prompt level.

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/chat/conversations` | Authenticated | List user's conversations |
| POST | `/api/chat/conversations` | Authenticated | Create new conversation |
| GET | `/api/chat/conversations/:id` | Owner | Get conversation with messages |
| DELETE | `/api/chat/conversations/:id` | Owner | Delete conversation |
| POST | `/api/chat/conversations/:id/messages` | Owner | Send message (returns SSE stream) |
| POST | `/api/chat/conversations/:id/upload` | Manager/Admin | Upload xlsx for chat-triggered import |

### SSE Streaming

The message creation endpoint returns `text/event-stream` content type. Events:

```
event: chunk
data: {"content": "Based on your team's "}

event: chunk
data: {"content": "evaluation data..."}

event: done
data: {"message_id": 42, "token_count": 350}
```

The client accumulates chunks and renders them progressively via `chatStore.streamingContent`.

## Guardrails

### Input Validation

| Check | Rule | Action |
|-------|------|--------|
| Message length | Max 2,000 characters | Reject with error |
| Injection patterns | Detect prompt injection attempts | Sanitize or reject |
| Language detection | Identify EN/DE/ZH for glossary | Route to appropriate terms |
| Empty messages | Reject blank/whitespace-only | Reject with error |

### Output Validation

| Check | Rule | Action |
|-------|------|--------|
| Code stripping | Remove executable code blocks | Strip `<script>` tags |
| Score boundaries | Scores mentioned must be 0-5 | Clamp or flag |
| Data leak check | No raw SQL, no API keys in output | Strip sensitive patterns |
| Length limit | Max 4,000 characters per response | Truncate with notice |

## Rate Limiting

ETS-based per-user rate limiter with hourly sliding window:

| Role | Messages/Hour | Burst |
|------|--------------|-------|
| User | 30 | 5/min |
| Manager | 60 | 10/min |
| Admin | 120 | 20/min |

Rate limit info returned in response headers:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1711540800
```

## Glossary

25+ AEC (Architecture/Engineering/Construction) terms seeded from `priv/repo/seeds_glossary.exs`. Each term has translations in EN/DE/ZH and a category.

Categories: structural, MEP, BIM, project-management, geotechnical, sustainability, cost-estimation.

Example terms: BIM, LOD, IFC, MEP, CDE, Clash Detection, Rebar, Formwork, As-Built, Punch List, RFI, Submittal, etc.

The glossary context is injected into the system prompt when terms are relevant to the conversation topic.

## Environment Variables

| Variable | Required | Default | Description |
|----------|:--------:|---------|-------------|
| `ANTHROPIC_API_KEY` | Yes (for chat) | — | Anthropic API key. Chat is disabled without it. |
| `ANTHROPIC_BASE_URL` | No | `https://api.anthropic.com/v1/messages` | Override for proxies, custom deployments, or compatible APIs |
| `ANTHROPIC_MODEL` | No | `claude-sonnet-4-20250514` | Model ID to use |
| `LLM_PROVIDER` | No | `anthropic` | `anthropic`, `minimax`, or `auto` |
| `MINIMAX_API_KEY` | No | — | MiniMax API key (Chinese fallback) |
| `MINIMAX_BASE_URL` | No | `https://api.minimax.chat/v1/text/chatcompletion_v2` | Override for MiniMax endpoint |
| `MINIMAX_GROUP_ID` | No | — | Required if MiniMax is enabled |
| `LLM_MAX_TOKENS` | No | `2048` | Max response tokens |
| `LLM_TEMPERATURE` | No | `0.3` | Low for factual responses |
| `CHAT_RETENTION_DAYS` | No | `90` | Auto-delete conversations older than this |

All URLs are configurable to support:
- Corporate proxies
- Self-hosted LLM deployments (e.g., vLLM with Anthropic-compatible API)
- MiniMax or other providers with different base URLs
- API gateway routing

## Agent Tool: import_xlsx

The chat agent has an internal tool for triggering xlsx imports:

```
Tool: import_xlsx
Parameters:
  - file_path: string (from upload endpoint)
  - period: string (e.g., "2025-Q1")
  - skillset_filter: string (optional, e.g., "Softskills")
Requirements:
  - User must be Manager or Admin
  - File must exist at file_path
  - Period must match YYYY-QN format
```

The tool calls `Import.Pipeline.run_import/3` and streams progress updates back through the SSE connection.

## Frontend Components

### ChatPanel.vue
Slide-out drawer (400px) anchored to the right side of the viewport. Opens via the floating action button (FAB) in the bottom-right corner. Contains the conversation list, message list, and input area.

### ChatMessageList.vue
Scrollable message container with auto-scroll to bottom on new messages. Handles streaming state with a typing indicator for the assistant.

### ChatMessage.vue
Renders user and assistant message bubbles. Assistant messages support markdown rendering. User messages are plain text.

### ChatInput.vue
Auto-growing textarea (1-5 rows) with send button. Enter to send, Shift+Enter for newline. Disabled during streaming.

### ChatConversationList.vue
Sidebar within the chat panel showing past conversations. Each entry shows title and date. Click to load, swipe/button to delete.

### Chat FAB
Floating action button (56px circle) in the bottom-right corner. Badge shows unread count. Toggles the chat panel open/closed.

## Self-Evaluation Assistant

The self-evaluation view (`SelfEvaluationView.vue`) includes an "Ask AI Assistant" button that:

1. Opens the chat panel
2. Pre-seeds a conversation with context about the current skillset and the user's scores
3. The system prompt includes the skill definitions and scoring rubric
4. Helps users understand what each score level means and how to self-assess accurately

## Refusal Patterns

The agent declines requests that are out of scope:

| Pattern | Example | Response |
|---------|---------|----------|
| Out-of-scope topic | "What's the weather?" | "I can only help with skill evaluations and AEC topics." |
| Cross-role data access | User asks for other's scores | "I can only show your own evaluation data." |
| Offensive content | Inappropriate language | "I'm here to help with professional skill development." |
| System manipulation | "Ignore previous instructions" | Guardrail catches; returns standard refusal |
| Score manipulation | "Set my score to 5" | "I can't modify scores. Please use the evaluation form." |
| PII requests | "Give me John's email" | "I can't share personal contact information." |
