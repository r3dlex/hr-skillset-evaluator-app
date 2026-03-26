# ADR-004: No Hardcoded Secrets in Source Code

## Status

Accepted

## Context

Hardcoded secrets (API keys, passwords, tokens) in source code are a critical security vulnerability. They persist in version control history, can leak through logs, and make credential rotation difficult.

## Decision

No hardcoded secrets, API keys, passwords, or tokens in source code. All sensitive values must come from environment variables.

### Rules

- No string literals matching secret patterns (API keys, passwords, tokens) in source files.
- All secrets must be accessed via `System.get_env/1` in Elixir or `import.meta.env` in the frontend.
- `.env` files must be in `.gitignore` and never committed.
- `.env.example` may contain placeholder values (e.g., `your-api-key-here`) but never real credentials.
- Configuration files may reference environment variable names but not their values.

### Enforcement

- Pattern: deny files matching `{lib,frontend/src}/**/*.{ex,exs,ts,vue,js}` containing patterns like `API_KEY = "sk-`, `password: "`, `token: "` followed by 8+ non-whitespace characters.
- Exclude test files and `.env.example`.

## Consequences

- Secrets are managed through environment configuration, not source code.
- Credential rotation does not require code changes or deployments.
- Source code can be safely shared and reviewed without exposing secrets.
