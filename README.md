# HR Skillset Evaluator

Interactive radar chart application for evaluating team members across multiple skillsets (Domain, Fullstack, UX, Product, AI, Softskills). Managers evaluate their teams; users submit self-assessments. Gap analysis highlights alignment between manager and self scores.

## Quick Start

```bash
cp .env.example .env
docker compose up --build
# Open http://localhost:4000
# Default admin: admin@example.com / admin123456
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Elixir 1.16, Phoenix 1.7, SQLite (ecto_sqlite3) |
| Frontend | Vue 3, TypeScript, Vite, Pinia, Tailwind CSS |
| Auth | Session-based (phx.gen.auth) + Microsoft Entra ID (ueberauth) |
| Import | Broadway pipeline + xlsxir for xlsx parsing |
| Pipeline | Python + Poetry pipeline runner, archgate/cli for ADR enforcement |
| CI/CD | GitHub Actions, Docker multi-stage builds |
| Infrastructure | Docker-only (zero host dependencies) |

## Architecture

```
Browser  -->  Phoenix (port 4000)
              ├── /api/*   JSON REST API (12 controllers, 4 contexts)
              └── /*       Vue SPA (built into priv/static/)
                           │
                           Ecto + ecto_sqlite3
                           │
                           SQLite DB (data/ volume mount)
```

One container, one port, one DB file. No external services.

## Project Structure

```
backend/         Phoenix app (Elixir)
  lib/skillset_evaluator/
    accounts/    User, UserToken, auth logic
    teams/       Team schema + context
    skills/      Skillset -> SkillGroup -> Skill hierarchy
    evaluations/ Evaluation schema + radar/gap queries
    import/      Broadway pipeline + XlsxParser
  lib/skillset_evaluator_web/
    controllers/ 12 controllers (auth, eval, radar, import, export...)
    plugs/       Auth plug (session + role enforcement)

frontend/        Vue 3 + TypeScript
  src/
    api/         Typed fetch client + domain API functions
    components/  RadarChart, GapAnalysis, DataInput, TeamLegend...
    stores/      Pinia: auth, skills, evaluations, team
    views/       Login, Dashboards, SkillsetView, Settings

tools/           Pipeline runner (Python + Poetry)
spec/           13 specification documents
.archgate/       5 ADRs with executable rules
.github/         CI/CD workflows
data/            xlsx files + SQLite DB (gitignored content)
```

## Roles

| Capability | Manager | User |
|------------|---------|------|
| View team members' radar charts | Yes | No |
| Set manager scores (0-5) | Yes | No |
| Submit self-evaluation scores | No | Yes (own only) |
| Import/export xlsx | Yes | No |
| Create skillsets and skills | Yes | No |
| View own radar chart | Yes | Yes |
| View gap analysis (manager vs self) | Yes | Yes (own) |

## Data Model

```
Team  --1:N--  User  --1:N--  Evaluation  --N:1--  Skill
                                                      |
                                              SkillGroup (N:1)
                                                      |
                                               Skillset (N:1)
```

Proficiency scale: 0 (None) to 5 (Expert). Evaluations track both `manager_score` and `self_score` per skill per period.

## xlsx Import

Upload a skill matrix xlsx file. The parser handles the 3-row header format:

- Row 1: Skill group names (merged cells spanning columns)
- Row 2: Priority per skill (Critical / High / Medium)
- Row 3: Column headers + skill names
- Row 4+: Person data with scores

Import uses Broadway-style concurrent processing for efficient bulk upserts.

## Running Tests

```bash
# Backend (68 ExUnit tests)
docker run --rm -e MIX_ENV=test -w /app/backend \
  $(docker build -q --target backend-build .) \
  sh -c "mix deps.get --quiet && mix test"

# Frontend (62 Vitest tests)
docker run --rm -w /app/frontend \
  $(docker build -q --target frontend-build .) \
  npx vitest run
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY_BASE` | Prod only | Phoenix secret (min 64 chars) |
| `DATABASE_PATH` | Prod only | Path to SQLite DB file |
| `PHX_HOST` | Prod only | Hostname for URL generation |
| `PORT` | No | Server port (default: 4000) |
| `MICROSOFT_CLIENT_ID` | OAuth only | Azure AD app client ID |
| `MICROSOFT_CLIENT_SECRET` | OAuth only | Azure AD app client secret |
| `MICROSOFT_TENANT_ID` | OAuth only | Azure AD tenant ID |
| `ADMIN_EMAIL` | No | Default admin email for seeds |
| `ADMIN_PASSWORD` | No | Default admin password for seeds |

## Specifications

All specs live in `spec/` and are numbered for execution order:

1. [Architecture](spec/01_ARCHITECTURE.md) -- System topology, KISS principles
2. [Data Model](spec/02_DATA_MODEL.md) -- SQLite schema, Ecto schemas
3. [Auth & Roles](spec/03_AUTH_AND_ROLES.md) -- Manager/User roles, OAuth
4. [API](spec/04_API.md) -- REST JSON endpoint contract
5. [Frontend](spec/05_FRONTEND.md) -- Vue components, routing, state
6. [Visualization](spec/06_VISUALIZATION.md) -- Radar chart rendering rules
7. [xlsx Import/Export](spec/07_XLSX_IMPORT_EXPORT.md) -- Broadway pipeline
8. [Testing](spec/08_TESTING.md) -- Coverage targets, test strategy
9. [Pipelines](spec/09_PIPELINES.md) -- archgate, CI/CD
10. [Troubleshooting](spec/10_TROUBLESHOOTING.md) -- Common issues
11. [Learnings](spec/11_LEARNINGS.md) -- Decision log
12. [Deployment](spec/12_DEPLOYMENT.md) -- Docker setup
13. [Design System](spec/13_DESIGN_SYSTEM.md) -- Colors, typography, components

## License

See [LICENSE](LICENSE).
