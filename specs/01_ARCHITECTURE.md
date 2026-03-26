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
/backend     — Phoenix app (Elixir)
/frontend    — Vue 3 + TypeScript (builds into backend/priv/static)
/tools       — Pipeline runner (Python/Poetry)
/data        — xlsx files + SQLite DB (volume mount, gitignored content)
/specs       — All specification documents
/.archgate   — ADRs and architectural rules
/.github     — GitHub Actions workflows
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
