# Agent Guidelines — HR Skillset Evaluator

## Project Overview

A skills radar chart application for HR evaluation. Managers evaluate team members across skillsets (Domain, Fullstack, UX, Product, AI, Softskills). Users view their evaluations and submit self-assessments. Visualized as interactive radar/spider charts.

## Tech Stack

- **Backend**: Elixir + Phoenix (non-umbrella), SQLite via `ecto_sqlite3`
- **Frontend**: Vue 3 + TypeScript, Vite, Pinia, served by Phoenix from `priv/static`
- **Pipeline**: Python + Poetry in `tools/pipeline_runner/`, uses `archgate/cli`
- **Infrastructure**: Docker-only (zero local installs), single multi-stage Dockerfile
- **Auth**: `phx.gen.auth` (email/password) + Microsoft Entra ID via `ueberauth`

## Spec Files (execute in order)

All specs live in `specs/` and are numbered for execution order:

1. `01_ARCHITECTURE.md` — System topology, KISS principles
2. `02_DATA_MODEL.md` — SQLite schema, Ecto schemas
3. `03_AUTH_AND_ROLES.md` — Auth flows, Manager/User roles
4. `04_API.md` — REST JSON API contract
5. `05_FRONTEND.md` — Vue components, routing, state
6. `06_VISUALIZATION.md` — Radar chart, gap analysis rendering
7. `07_XLSX_IMPORT_EXPORT.md` — Bidirectional xlsx sync
8. `08_TESTING.md` — Test strategy and coverage targets
9. `09_PIPELINES.md` — archgate, CI/CD, pipeline runner
10. `10_TROUBLESHOOTING.md` — Common issues
11. `11_LEARNINGS.md` — Decision log
12. `12_DEPLOYMENT.md` — Docker setup
13. `13_DESIGN_SYSTEM.md` — Visual design tokens

## Code Conventions

- **Elixir**: Follow standard `mix format`, contexts pattern (Accounts, Skills, Evaluations, Teams)
- **Vue/TS**: Composition API, `<script setup>`, strict TypeScript, components in PascalCase
- **Python**: Black formatting, type hints, Poetry for deps
- **General**: No secrets in repo. Use env vars. KISS over cleverness.

## Key Rules

- `data/` folder uses `.gitkeep`; all `*.xlsx` files are gitignored
- SQLite DB file lives at `backend/data/skillset_evaluator.db` (gitignored, Docker volume)
- Frontend builds to `backend/priv/static/` — Phoenix serves the SPA
- All tooling runs in Docker containers — no host dependencies assumed
- `archgate check` must pass before any commit
