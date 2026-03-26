# 09 — Pipelines

## Overview

All pipelines run in Docker. The `tools/pipeline_runner/` Python project orchestrates checks. `archgate/cli` enforces ADR-based architectural rules.

## archgate Setup

### Initialization

```bash
npx archgate init
```

Creates `.archgate/` directory with:
- `adr/` — Architecture Decision Records
- `rules/` — Executable `.rules.ts` files

### ADRs to Create

| ADR | Rule | Description |
|-----|------|-------------|
| `001-no-raw-sql.md` | `001-no-raw-sql.rules.ts` | All DB access through Ecto. No raw SQL strings. |
| `002-api-json-only.md` | `002-api-json-only.rules.ts` | API controllers return JSON only. |
| `003-component-naming.md` | `003-component-naming.rules.ts` | Vue components use PascalCase. |
| `004-no-secrets.md` | `004-no-secrets.rules.ts` | No hardcoded secrets, tokens, or passwords. |
| `005-typed-api.md` | `005-typed-api.rules.ts` | All API calls use typed client, no raw fetch. |

### Running

```bash
npx archgate check
```

## Pipeline Runner (tools/pipeline_runner/)

### Project Structure

```
tools/pipeline_runner/
  Dockerfile
  pyproject.toml
  pipeline_runner/
    __init__.py
    runner.py          # Main orchestrator
    stages/
      __init__.py
      lint.py          # Elixir format check + eslint
      typecheck.py     # TypeScript strict check
      test.py          # ExUnit + Vitest
      build.py         # Mix release + Vite build
      archgate.py      # archgate check
      security.py      # Secret scanning
    config.py          # Stage configuration
```

### Pipeline Stages (in order)

1. **security** — Scan for secrets (no .env values, no API keys in source)
2. **lint** — `mix format --check-formatted` + `npx eslint`
3. **typecheck** — `npx vue-tsc --noEmit`
4. **archgate** — `npx archgate check`
5. **test** — `mix test` + `npm run test`
6. **build** — `npm run build` + `mix release`

### Orchestrator (runner.py)

```python
"""Pipeline runner — executes stages sequentially, fails fast."""

import subprocess
import sys
from dataclasses import dataclass

@dataclass
class StageResult:
    name: str
    success: bool
    output: str
    duration_ms: int

def run_pipeline(stages: list[str] | None = None) -> list[StageResult]:
    """Run all or specified pipeline stages."""
    ...
```

### CLI Interface

```bash
# Run all stages
python -m pipeline_runner

# Run specific stages
python -m pipeline_runner --stages lint,test

# Dry run (show what would execute)
python -m pipeline_runner --dry-run
```

## GitHub Actions

### Workflow: `.github/workflows/ci.yml`

Triggers: push to `main`, pull requests. Three parallel jobs:

```
ci.yml
├── backend-test     Elixir 1.16 + OTP 26
│   ├── mix deps.get
│   ├── mix format --check-formatted
│   ├── mix compile --warnings-as-errors
│   └── mix test
│
├── frontend-test    Node.js 20
│   ├── npm ci
│   ├── npx vue-tsc --noEmit
│   ├── npx eslint src --ext .ts,.vue
│   └── npx vitest run
│
└── docker-build     (depends on both above)
    └── docker build -t hr-skillset-evaluator .
```

### Workflow: `.github/workflows/security.yml`

Triggers: push (all branches).

Scans for:
- Secrets in source via trufflehog (only verified secrets)
- npm dependency vulnerabilities (`npm audit --audit-level=high`)
- Hex dependency vulnerabilities (`mix deps.audit`)

## Local Development Pipeline

```bash
# Run full pipeline locally via Docker
docker compose --profile tools run --rm pipeline-runner

# Run specific stages
docker compose --profile tools run --rm pipeline-runner \
  python -m pipeline_runner -s security -s archgate

# Run backend tests directly
cd backend && mix test

# Run frontend tests directly
cd frontend && npx vitest run

# Run archgate check only
cd . && npx archgate check
```

## Pre-commit Hook (optional)

Via `archgate` CLI which supports pre-commit integration:

```bash
npx archgate hook install
```

This runs `archgate check` before each commit.
