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
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│     Pipeline Runner (separate container)    │
│     Python + archgate/cli + test runners    │
└─────────────────────────────────────────────┘
```

## Monorepo Structure

```
/backend          Phoenix app (Elixir 1.16 + Phoenix 1.7)
  /lib/skillset_evaluator/        Contexts: Accounts, Teams, Skills, Evaluations, Import
  /lib/skillset_evaluator_web/    Controllers (12), Plugs, Router, Endpoint
  /priv/repo/migrations/          7 Ecto migrations (teams, users, tokens, skillsets, groups, skills, evaluations)
  /priv/static/                   Vue SPA build output (gitignored, populated at build time)
  /test/                          68 ExUnit tests
/frontend         Vue 3 + TypeScript (builds into backend/priv/static)
  /src/api/                       Typed fetch client + domain API functions
  /src/components/                RadarChart, GapAnalysis, DataInput, TeamLegend, etc.
  /src/stores/                    Pinia: auth, skills, evaluations, team
  /src/views/                     Login, Dashboards, SkillsetView, Settings
  /src/layouts/                   AuthLayout, AppLayout (sidebar + content)
  62 Vitest tests
/tools            Pipeline runner (Python 3.12 + Poetry)
  /pipeline_runner/stages/        security, lint, typecheck, archgate, test, build
/data             xlsx files + SQLite DB (volume mount, gitignored content)
/specs            13 specification documents (numbered 01-13)
/.archgate        5 ADRs with executable rules
/.github          CI/CD workflows (ci.yml, security.yml)
```

## Request Flow

1. Browser hits `http://localhost:4000`
2. Phoenix serves Vue SPA from `priv/static/`
3. Vue SPA makes API calls to `/api/*`
4. Phoenix controllers delegate to contexts (Accounts, Skills, Evaluations, Teams)
5. Contexts interact with SQLite via Ecto

## Key Constraints

- No external services (no Redis, no message queues, no external DB servers)
- SQLite WAL mode for read concurrency
- All config via environment variables (12-factor)
- Frontend build is a build-time step, not a runtime dependency
