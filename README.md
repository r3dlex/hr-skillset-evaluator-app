<p align="center">
  <img src="assets/logo-light.svg" alt="SkillForge" width="240" />
</p>

<p align="center">
  <strong>The AI-powered competency platform that finally makes skill evaluations matter.</strong>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#capabilities">Capabilities</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#ai-assistant">AI Assistant</a> •
  <a href="#running-tests">Tests</a>
</p>

---

SkillForge turns messy Excel skill matrices into an interactive intelligence platform. Managers and their teams finally share a single source of truth — live radar charts, instant gap analysis, and an AI chat assistant that knows your team's data in real time.

## Quick Start

```bash
cp .env.example .env
docker compose up --build
# Open http://localhost:4000
# Default admin: admin@example.com / admin123456
```

One command. One container. No host dependencies.

---

## Capabilities

### For Managers

- **Live radar charts** — visualize every team member's competency profile across 7 skill domains at a glance
- **Manager & self-assessment side-by-side** — instantly see where your team's perception matches (or doesn't match) reality
- **Gap analysis** — one-click view of which skills need the most development attention, with role-average benchmarking
- **Multi-team support** — manage members across multiple teams simultaneously (one person, many teams)
- **Role filter** — slice your dashboard by job title: Dev, QE, PM, PO, UX, AI, Lead — instantly
- **Location filter** — filter by region/country for globally distributed teams
- **xlsx import** — drop in your existing skill matrix and SkillForge parses it automatically, handling 3-row merged-cell headers, emoji priority flags, and bulk concurrent upserts via Broadway
- **xlsx export** — export any view back to Excel for offline sharing
- **Assessment periods** — track progress quarterly or half-yearly; all historical data is preserved
- **AI Import Assistant** — upload your xlsx via the chat and let the AI trigger an import for you

### For Individual Contributors

- **Self-evaluation UI** — score yourself on a smooth 0–5 slider, see your manager's scores in context
- **Personal radar chart** — your own skill profile, always up to date
- **Personal gap analysis** — see where you rate yourself versus your manager's assessment
- **Role-specific skillsets** — only see the skillsets that apply to your role (no clutter)
- **Guided onboarding tour** — step-by-step walkthrough the first time you log in
- **AI career coach** — ask SkillBot anything about your scores, development areas, or what each proficiency level means

### The AI Chat Assistant (SkillBot)

SkillForge ships with a built-in AI assistant powered by Claude — no configuration needed:

- **Context-aware**: SkillBot knows which screen you're on, what team you manage, and what period you're viewing
- **Role-enforced**: users only ever see their own data; managers see their team; admins see everything
- **GDPR-safe**: strict output guardrails prevent leaking cross-user data even if asked
- **Multi-locale**: routes to MiniMax for Chinese-locale users, Claude for everyone else
- **Streaming responses**: SSE real-time token streaming for a native feel
- **Rate-limited**: per-role request limits (30/hr user, 60/hr manager, 120/hr admin)
- **Conversation history**: full conversation threading with search and bulk delete
- **xlsx tool use**: managers can trigger imports directly from the chat window

### Platform Highlights

| Feature | Detail |
|---------|--------|
| Zero-install | Docker-only, no host dependencies required |
| Single binary | One container, one port (4000), one SQLite file |
| Microsoft SSO | Ueberauth + Azure Entra ID OAuth, or local email/password |
| Live radar charts | Chart.js with per-skill, per-member, per-group drill-down |
| Streaming AI | SSE token streaming with error classification and retries |
| Concurrent import | Broadway pipeline for parallel xlsx row processing |
| ADR enforcement | archgate/cli validates architecture decisions in CI |
| Test coverage | Backend 80.8% · Frontend 98.3% (906 tests, 0 failures) |

---

## Architecture

```
Browser  -->  Phoenix (port 4000)
              ├── /api/*   JSON REST API (14 controllers, 4 contexts)
              └── /*       Vue SPA (built into priv/static/)
                           │
                           Ecto + ecto_sqlite3
                           │
                           SQLite DB (data/ volume mount)
```

One container, one port, one DB file. No external services required in development or production.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Elixir 1.16, Phoenix 1.7, SQLite (ecto_sqlite3) |
| Frontend | Vue 3, TypeScript, Vite, Pinia, Tailwind CSS |
| Auth | Session-based (phx.gen.auth) + Microsoft Entra ID (Ueberauth) |
| AI | Claude (Anthropic) via SSE streaming + MiniMax for zh-CN |
| Import | Broadway producer + xlsxir for concurrent xlsx parsing |
| Pipeline | Python + Poetry runner, archgate/cli for ADR enforcement |
| CI/CD | GitHub Actions, Docker multi-stage builds |
| Infrastructure | Docker-only (zero host dependencies) |

## Project Structure

```
backend/         Phoenix app (Elixir)
  lib/skillset_evaluator/
    accounts/    User, UserToken, auth logic
    teams/       Team, UserTeam schemas + context (many-to-many)
    skills/      Skillset -> SkillGroup -> Skill hierarchy
    evaluations/ Evaluation schema + radar/gap/dashboard queries
    assessments/ Assessment periods (e.g., "2025-Q1")
    chat/        Conversation + Message schemas + context
    import/      Broadway pipeline + XlsxParser
    llm/         Anthropic + MiniMax providers, ContextBuilder, Guardrails, RateLimiter
    glossary/    Domain glossary terms for AI context injection
  lib/skillset_evaluator_web/
    controllers/ 14 controllers (auth, eval, radar, gap-analysis, dashboard, import, export, chat...)
    plugs/       Auth plug (session + role enforcement)

frontend/        Vue 3 + TypeScript
  src/
    api/         Typed fetch client + domain API functions
    components/  RadarChart, GapAnalysis, DataInput, TeamLegend, Overview, ChatPanel, TourTooltip...
    composables/ useTour, useScreenContext
    stores/      Pinia: auth, skills, evaluations, team, chat, onboarding, theme
    views/       Login, Dashboards, SkillsetView, SelfEvaluationView, SettingsView
    layouts/     AppLayout, AuthLayout

tools/           Pipeline runner (Python + Poetry)
spec/           15 specification documents
.archgate/       5 ADRs with executable rules
.github/         CI/CD workflows
data/            xlsx files + SQLite DB (gitignored)
```

## Roles

| Capability | Admin | Manager | User |
|------------|-------|---------|------|
| View all teams' radar charts | Yes | Own team | No |
| Set manager scores (0-5) | Yes | Yes | No |
| Submit self-evaluation | Yes | Yes | Yes (own) |
| Import/export xlsx | Yes | Yes | No |
| AI import via chat | Yes | Yes | No |
| Create skillsets and skills | Yes | Yes | No |
| View own radar chart | Yes | Yes | Yes |
| Gap analysis (manager vs self vs team avg vs role avg) | Yes | Yes | Own only |
| Filter by region/location | Yes | Yes | No |
| Filter by role (job title) | Yes | Yes | No |
| Switch between teams | Yes | Yes | No |
| Manage users | Yes | No | No |

## Skillset-Role Mapping

Users see only the skillsets applicable to their role:

| Skillset | Applicable Roles |
|----------|-----------------|
| Soft Skills | All roles |
| Domain | All roles |
| Application Development | Dev, QE, DevOps, Lead |
| Product | UX, PM, PO, Lead |
| AI | AI |
| UX | UX |
| QE | QE |

Lead role has the union of Dev and PO scopes.

## Data Model

```
Team  --N:M--  User  --1:N--  Evaluation  --N:1--  Skill
 (via user_teams)                                     |
                                              SkillGroup (N:1)
                                                      |
                                               Skillset (N:1)

User  --1:N--  Conversation  --1:N--  Message

Assessment --1:N-- Evaluation
```

- Users can belong to **multiple teams** (e.g., Florian Haag in both BIM and TA-DE)
- Proficiency scale: 0 (None) to 5 (Expert) with descriptive labels
- Evaluations track both `manager_score` and `self_score` per skill per period
- Gap analysis computes team averages and role averages for comparison
- Assessments are named periods (e.g., "2025-Q1") linked to evaluation snapshots
- Conversations thread per-user with full message history and search

## xlsx Import

Upload a skill matrix xlsx file. The parser handles the 3-row header format:

- Row 1: Skill group names (merged cells spanning columns)
- Row 2: Priority per skill (supports emoji-prefixed values like "🔴 Critical", "🟠 High", "🟡 Medium")
- Row 3: Column headers + skill names
- Row 4+: Person data with scores

Import uses Broadway-style concurrent processing for efficient bulk upserts. Re-importing updates existing data (priorities, user details, team memberships). Duplicate-safe upserts ensure idempotent imports.

## AI Assistant

SkillBot is a multi-layer AI assistant that knows your team's data:

1. **Agent identity** — loaded from `llm/AGENTS.md`, with role-specific behavior rules
2. **Domain glossary** — AEC construction terms + application glossary injected for context
3. **User context** — role-scoped live data (admin: all users; manager: team; user: self)
4. **Screen context** — real-time data from the user's current view (which skillset, which tab, which period)
5. **Data access rules** — GDPR/compliance harness enforced in every response

Configure with `ANTHROPIC_API_KEY`. Optional: `MINIMAX_API_KEY` + `MINIMAX_GROUP_ID` for Chinese locale routing.

## Running Tests

```bash
# Backend (ExUnit + ExCoveralls)
docker compose run --rm app mix test --cover

# Frontend (Vitest + @vitest/coverage-v8)
docker compose run --rm frontend npx vitest run --coverage
```

Current status: **461 backend tests · 445 frontend tests · 0 failures**

Coverage: **Backend 80.8% · Frontend 98.3%**

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY_BASE` | Prod only | Phoenix secret (min 64 chars) |
| `DATABASE_PATH` | Prod only | Path to SQLite DB file |
| `PHX_HOST` | Prod only | Hostname for URL generation |
| `PORT` | No | Server port (default: 4000) |
| `ANTHROPIC_API_KEY` | AI features | Claude API key |
| `ANTHROPIC_MODEL` | No | Override model (default: claude-sonnet-4-20250514) |
| `MINIMAX_API_KEY` | zh-CN only | MiniMax API key for Chinese locale |
| `MINIMAX_GROUP_ID` | zh-CN only | MiniMax group ID |
| `MICROSOFT_CLIENT_ID` | OAuth only | Azure AD app client ID |
| `MICROSOFT_CLIENT_SECRET` | OAuth only | Azure AD app client secret |
| `MICROSOFT_TENANT_ID` | OAuth only | Azure AD tenant ID |
| `ADMIN_EMAIL` | No | Default admin email for seeds |
| `ADMIN_PASSWORD` | No | Default admin password for seeds |

## Specifications

All specs live in `spec/` and are numbered for execution order:

1. [Architecture](spec/01_ARCHITECTURE.md) — System topology, KISS principles
2. [Data Model](spec/02_DATA_MODEL.md) — SQLite schema, Ecto schemas
3. [Auth & Roles](spec/03_AUTH_AND_ROLES.md) — Manager/User/Admin roles, OAuth
4. [API](spec/04_API.md) — REST JSON endpoint contract
5. [Frontend](spec/05_FRONTEND.md) — Vue components, routing, state
6. [Visualization](spec/06_VISUALIZATION.md) — Radar chart rendering rules
7. [xlsx Import/Export](spec/07_XLSX_IMPORT_EXPORT.md) — Broadway pipeline
8. [Testing](spec/08_TESTING.md) — Coverage targets, test strategy
9. [Pipelines](spec/09_PIPELINES.md) — archgate, CI/CD
10. [Troubleshooting](spec/10_TROUBLESHOOTING.md) — Common issues
11. [Learnings](spec/11_LEARNINGS.md) — Decision log
12. [Deployment](spec/12_DEPLOYMENT.md) — Docker setup
13. [Design System](spec/13_DESIGN_SYSTEM.md) — Colors, typography, components
14. [Onboarding](spec/14_ONBOARDING.md) — Guided tour, checklist
15. [AI Chat Agent](spec/15_AI_CHAT_AGENT.md) — SkillBot architecture, prompts, guardrails

## License

See [LICENSE](LICENSE).
