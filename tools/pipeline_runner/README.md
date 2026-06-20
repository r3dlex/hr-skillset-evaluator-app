# Pipeline Runner

[![Python](https://img.shields.io/badge/python-3.12%2B-blue.svg)](pyproject.toml)
[![Tooling](https://img.shields.io/badge/tooling-uv%20%2B%20hatchling-green.svg)](pyproject.toml)
[![Coverage](https://img.shields.io/badge/coverage-90%25-green.svg)](pyproject.toml)

`pipeline-runner` is the Python command line wrapper for SkillForge pipeline stages. It runs security, lint, typecheck, archgate, test, and build commands in the expected order.

## Install

```bash
uv sync --group dev
```

## Run

```bash
uv run pipeline-runner
uv run pipeline-runner --stages test
uv run pipeline-runner --no-fail-fast
```

## Verify

```bash
uv run ruff format --check pipeline_runner tests
uv run ruff check pipeline_runner tests
uv run mypy pipeline_runner tests
uv run pytest
uv build
```

## Release-grade checks

This submodule uses:

- uv dependency management with `[dependency-groups]`
- hatchling build backend
- ruff lint and format checks
- mypy strict mode
- pytest with coverage gate
- a focused GitHub Actions CI job on pull requests
