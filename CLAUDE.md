# SkillForge

All agent instructions and behavioral guidelines are defined in [AGENTS.md](./AGENTS.md).

Refer to `AGENTS.md` for:
- Project context and goals
- Spec file locations and execution order
- Architecture decisions
- Code style and conventions
- Testing and pipeline requirements

## Quick Reference

- **Backend**: `backend/` -- Elixir + Phoenix 1.7 + SQLite
- **Frontend**: `frontend/` -- Vue 3 + TypeScript + Vite + Pinia + Tailwind
- **Pipeline**: `tools/pipeline_runner/` -- Python + Poetry + archgate/cli
- **Specs**: `spec/01_ARCHITECTURE.md` through `spec/13_DESIGN_SYSTEM.md`
- **ADRs**: `.archgate/adr/001-no-raw-sql.md` through `005-typed-api.md`
- **CI**: `.github/workflows/ci.yml` (backend tests, frontend tests, Docker build)

## Running

```bash
docker compose up --build        # Production
docker compose run --rm app mix test   # Backend tests
```

## Key Constraints

- Zero-install: Docker-only, no host dependencies
- No secrets in repo: all config via env vars
- `data/*.xlsx` and `*.db` are gitignored
- Frontend builds to `backend/priv/static/` -- Phoenix serves the SPA
