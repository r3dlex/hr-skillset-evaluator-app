# 01 — Architecture

## Principles

- **KISS**: Minimal moving parts. One container, one DB file, one port.
- **Zero-install**: Docker-only. No host dependencies beyond Docker + docker-compose.
- **Clean Architecture**: Phoenix contexts isolate business logic from web layer.

## System Topology

```
┌─────────────────────────────────────────────┐
│              Docker Container               │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │         Phoenix (port 4000)         │    │
│  │                                     │    │
│  │  ┌──────────┐  ┌────────────────┐   │    │
│  │  │ JSON API │  │ Static Files   │   │    │
│  │  │ /api/*   │  │ Vue SPA (/)    │   │    │
│  │  └──────────┘  └────────────────┘   │    │
│  │                                     │    │
│  │  ┌──────────────────────────────┐   │    │
│  │  │    Ecto + ecto_sqlite3       │   │    │
│  │  └──────────┬───────────────────┘   │    │
│  └─────────────┼───────────────────────┘    │
│                │                            │
│  ┌─────────────▼───────────────────────┐    │
│  │  SQLite DB (data/ volume mount)     │    │
│  │  ├── users, teams, evaluations ...  │    │
│  │  ├── chat_conversations, messages   │    │
│  │  └── glossary_terms (EN/DE/ZH)     │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│     Pipeline Runner (separate container)    │
│     Python + archgate/cli + test runners    │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  LLM Client (Anthropic / MiniMax API)       │
│  External HTTP calls from Phoenix           │
│  SSE-streamed responses back to client      │
└─────────────────────────────────────────────┘
```

## Monorepo Structure

```
/backend          Phoenix app (Elixir 1.16 + Phoenix 1.7)
  /lib/skillset_evaluator/        Contexts: Accounts, Teams, Skills, Evaluations, Import
  /lib/skillset_evaluator/chat/        Chat context: conversations, messages
  /lib/skillset_evaluator/glossary/    Glossary context: AEC terms (EN/DE/ZH)
  /lib/skillset_evaluator/llm/         LLM provider abstraction, guardrails, rate limiter
  /lib/skillset_evaluator_web/    Controllers (13+), Plugs, Router, Endpoint
  /priv/repo/migrations/          10 Ecto migrations (teams, users, tokens, skillsets, groups, skills, evaluations, chat, glossary, admin role)
  /priv/static/                   Vue SPA build output (gitignored, populated at build time)
  /test/                          84 ExUnit tests
/frontend         Vue 3 + TypeScript (builds into backend/priv/static)
  /src/api/                       Typed fetch client + domain API functions
  /src/components/                RadarChart, GapAnalysis, DataInput, TeamLegend, chat/, etc.
  /src/stores/                    Pinia: auth, skills, evaluations, team, chat, theme
  /src/views/                     Login, Dashboards, SkillsetView, Settings
  /src/layouts/                   AuthLayout, AppLayout (sidebar + content)
  85 Vitest tests
/tools            Pipeline runner (Python 3.12 + Poetry)
  /pipeline_runner/stages/        security, lint, typecheck, archgate, test, build
/data             xlsx files + SQLite DB (volume mount, gitignored content)
/specs            15 specification documents (numbered 01-15)
/.archgate        5 ADRs with executable rules
/.github          CI/CD workflows (ci.yml, security.yml)
```

## Request Flow

1. Browser hits `http://localhost:4000`
2. Phoenix serves Vue SPA from `priv/static/`
3. Vue SPA makes API calls to `/api/*`
4. Phoenix controllers delegate to contexts (Accounts, Skills, Evaluations, Teams)
5. Contexts interact with SQLite via Ecto
6. Chat requests: Vue → `/api/chat/*` → ChatController → LLM Client → Anthropic API (SSE stream)
7. LLM Context Builder assembles role-scoped system prompt before each API call

## Key Constraints

- No external services (no Redis, no message queues, no external DB servers)
- SQLite WAL mode for read concurrency
- All config via environment variables (12-factor)
- Frontend build is a build-time step, not a runtime dependency
- LLM API calls are stateless HTTP -- no persistent connection, no WebSocket
- Anthropic API key from env var, never in source
