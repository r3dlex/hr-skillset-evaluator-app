# ADR-003: Vue Component Naming Conventions

## Status

Accepted

## Context

Consistent component naming makes the codebase navigable and prevents conflicts with HTML elements. The Vue.js style guide recommends PascalCase for single-file components.

## Decision

All Vue components must use PascalCase for both filenames and component names.

### Rules

- All `.vue` files in `frontend/src/` must use PascalCase filenames (e.g., `SkillMatrix.vue`, not `skill-matrix.vue`).
- Multi-word component names are required (e.g., `SkillMatrix`, not `Matrix`) to avoid conflicts with HTML elements.
- Component names registered via `defineComponent` or `<script setup>` must match the filename.
- Index files (`index.vue`) are not permitted; use explicit names.

### Enforcement

- Pattern: deny files matching `frontend/src/**/*.vue` where the filename contains a hyphen or starts with a lowercase letter.
- Pattern: deny files matching `frontend/src/**/index.vue`.

## Consequences

- Consistent, predictable component discovery.
- No collisions with native HTML elements.
- Aligns with Vue.js style guide recommendations.
