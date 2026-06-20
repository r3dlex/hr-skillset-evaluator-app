# Contributing

## Local setup

```bash
uv sync --group dev
```

## Required checks

Run these before opening a PR:

```bash
uv run ruff format --check pipeline_runner tests
uv run ruff check pipeline_runner tests
uv run mypy pipeline_runner tests
uv run pytest
uv build
```

Keep changes small and target one pipeline-runner concern per PR.
