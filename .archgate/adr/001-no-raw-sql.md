# ADR-001: No Raw SQL in Application Code

## Status

Accepted

## Context

Direct SQL strings in application code bypass Ecto's query builder, schema validation, and parameterization. This creates risks for SQL injection, makes queries harder to maintain, and breaks the abstraction layer that Ecto provides.

## Decision

All database access must go through Ecto queries, schemas, and changesets. No raw SQL strings are permitted in application code.

### Rules

- Use `Ecto.Query` for all database queries.
- Use `Ecto.Changeset` for all data validation and insertion.
- No `Ecto.Adapters.SQL.query/3` or `Ecto.Adapters.SQL.query!/3` calls in `lib/` (excluding migrations).
- No string interpolation or concatenation to build SQL.
- Raw SQL is permitted only in Ecto migrations (`priv/repo/migrations/`).

### Enforcement

- Pattern: deny files matching `lib/**/*.ex` containing `Ecto.Adapters.SQL.query` or `~s"SELECT` or `~s"INSERT` or `~s"UPDATE` or `~s"DELETE`.
- Migrations in `priv/repo/migrations/` are excluded from this rule.

## Consequences

- All queries benefit from Ecto compile-time checks and parameterized bindings.
- Database operations are testable via Ecto sandbox.
- Schema changes are reflected consistently across the codebase.
