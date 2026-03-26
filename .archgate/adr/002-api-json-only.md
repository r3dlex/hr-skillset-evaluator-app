# ADR-002: API Endpoints Return JSON Only

## Status

Accepted

## Context

The HR Skillset Evaluator uses a decoupled architecture with a Vue.js frontend and Phoenix API backend. API controllers should not render HTML, as that conflates the API layer with server-side rendering concerns.

## Decision

All API endpoints must return JSON responses. No HTML rendering from API controllers.

### Rules

- Controllers under `lib/skillset_evaluator_web/controllers/` must use `json/2` for responses.
- No `render/3` calls that produce HTML in API controllers.
- No Phoenix HTML templates (`.heex`) associated with API controllers.
- The `SkillsetEvaluatorWeb.ErrorJSON` module handles error formatting.

### Enforcement

- Pattern: deny files matching `lib/skillset_evaluator_web/controllers/**/*.ex` containing `render(conn, "` followed by `.html`.
- Pattern: deny files matching `lib/skillset_evaluator_web/controllers/**/*.ex` containing `Phoenix.HTML`.

## Consequences

- Clean separation between API and frontend concerns.
- API responses are consistently machine-readable.
- Frontend is fully responsible for presentation.
