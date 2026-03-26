# Agent Guidelines -- HR Skillset Evaluator

## Project Overview

A skills radar chart application for HR evaluation. Managers evaluate team members across skillsets (Domain, Fullstack, UX, Product, AI, Softskills). Users view their evaluations and submit self-assessments. Visualized as interactive radar/spider charts with gap analysis.

## Tech Stack

- **Backend**: Elixir 1.16 + Phoenix 1.7 (non-umbrella), SQLite via `ecto_sqlite3`
- **Frontend**: Vue 3 + TypeScript (strict), Vite, Pinia, Tailwind CSS -- served by Phoenix from `priv/static`
- **Import**: Broadway pipeline + `xlsxir` for xlsx parsing with concurrent upserts
- **Pipeline**: Python 3.12 + Poetry in `tools/pipeline_runner/`, archgate/cli for ADR enforcement
- **Infrastructure**: Docker-only (zero local installs), multi-stage Dockerfile (Node + Elixir + Alpine runtime)
- **Auth**: Session-based (email/password) + Microsoft Entra ID via `ueberauth`
- **CI/CD**: GitHub Actions (backend tests, frontend tests, Docker build, security scan)

## Spec Files (execute in order)

All specs live in `specs/` and are numbered for execution order:

1. `01_ARCHITECTURE.md` -- System topology, KISS principles, monorepo layout
2. `02_DATA_MODEL.md` -- 7 Ecto schemas, SQLite tables, relationships, xlsx mapping
3. `03_AUTH_AND_ROLES.md` -- Auth flows, Manager/User roles, route protection
4. `04_API.md` -- Full REST JSON API contract with request/response examples
5. `05_FRONTEND.md` -- Vue component tree, Pinia stores, routing, API client
6. `06_VISUALIZATION.md` -- SVG radar chart rendering, gap analysis chart, animations
7. `07_XLSX_IMPORT_EXPORT.md` -- Broadway pipeline architecture, sheet parsing, import/export
8. `08_TESTING.md` -- Coverage targets, test structure (68 backend + 62 frontend tests)
9. `09_PIPELINES.md` -- archgate ADRs, pipeline runner stages, GitHub Actions
10. `10_TROUBLESHOOTING.md` -- Common issues with SQLite, Phoenix, Vue, Docker, OAuth, xlsx
11. `11_LEARNINGS.md` -- Decision log (SQLite over PG, SVG over D3, non-umbrella, etc.)
12. `12_DEPLOYMENT.md` -- Docker setup, env vars, seed data, production notes
13. `13_DESIGN_SYSTEM.md` -- Color palette, typography, spacing, component styles

## Architecture Decision Records

Enforced via archgate/cli (`.archgate/adr/`):

1. **ADR-001**: No raw SQL -- all DB access through Ecto queries and changesets
2. **ADR-002**: API JSON only -- controllers return JSON, no HTML rendering
3. **ADR-003**: Component naming -- Vue files use PascalCase, multi-word names
4. **ADR-004**: No secrets -- all sensitive values from env vars, never hardcoded
5. **ADR-005**: Typed API client -- no raw `fetch()` in components or stores

## Phoenix Contexts

| Context | Responsibility | Key Modules |
|---------|---------------|-------------|
| `Accounts` | User CRUD, auth, password hashing, session tokens | `User`, `UserToken` |
| `Teams` | Team management, member queries | `Team` |
| `Skills` | Skillset/SkillGroup/Skill hierarchy, CRUD | `Skillset`, `SkillGroup`, `Skill` |
| `Evaluations` | Score management, radar data, gap analysis | `Evaluation` |
| `Import` | xlsx parsing, Broadway pipeline, bulk upserts | `XlsxParser`, `Pipeline`, `BroadwayProducer` |

## Code Conventions

- **Elixir**: `mix format`, contexts pattern, pattern matching over conditionals, doctypes on public functions
- **Vue/TS**: Composition API with `<script setup lang="ts">`, strict TypeScript, PascalCase components
- **Python**: Black formatting, type hints everywhere, Poetry for deps, dataclasses over dicts
- **General**: No secrets in repo. Use env vars. KISS over cleverness. Fail fast.

## Key Rules

- `data/` folder uses `.gitkeep`; all `*.xlsx` and `*.db` files are gitignored
- Frontend builds to `backend/priv/static/` -- Phoenix serves the SPA at `/`
- All tooling runs in Docker containers -- no host dependencies assumed
- Security scan runs on every push (trufflehog + dependency audits)
- 68 backend tests (ExUnit) + 62 frontend tests (Vitest) must pass before merge

## Test Commands

```bash
# Backend
cd backend && mix test

# Frontend
cd frontend && npx vitest run

# Coverage
cd backend && mix test --cover
cd frontend && npx vitest run --coverage
```
