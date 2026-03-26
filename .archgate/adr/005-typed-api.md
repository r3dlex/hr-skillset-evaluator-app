# ADR-005: Typed API Client for Frontend

## Status

Accepted

## Context

Scattered `fetch()` calls across components and stores lead to inconsistent error handling, duplicated configuration (base URL, headers, auth tokens), and make it difficult to add cross-cutting concerns like request logging or retry logic.

## Decision

All frontend API calls must use the typed API client at `src/api/client.ts`. No raw `fetch()` calls in components or stores.

### Rules

- All HTTP requests to the backend must go through `src/api/client.ts`.
- No direct `fetch()`, `XMLHttpRequest`, or `axios` calls in `.vue` files or Pinia stores.
- The API client handles base URL, authentication headers, error transformation, and response typing.
- API resource modules (e.g., `src/api/skills.ts`, `src/api/evaluations.ts`) wrap client calls with typed request/response interfaces.

### Enforcement

- Pattern: deny files matching `frontend/src/{components,views,stores}/**/*.{ts,vue}` containing `fetch(` or `new XMLHttpRequest` or `axios.`.
- Files in `frontend/src/api/` are excluded from this rule.

## Consequences

- Consistent error handling and authentication across all API calls.
- Type safety for request and response payloads.
- Single point for adding interceptors, retry logic, or request logging.
- API changes can be reflected in one place with TypeScript compiler catching consumers.
