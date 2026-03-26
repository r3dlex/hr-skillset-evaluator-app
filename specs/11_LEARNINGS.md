# 11 — Learnings & Decision Log

## Initial Decisions

### SQLite over PostgreSQL
**Decision**: Use SQLite with ecto_sqlite3.
**Why**: ~200 users, ~500 skills, ~10k evaluations. SQLite handles this trivially. Zero operational overhead. Single file backup. WAL mode provides adequate read concurrency. No external service to manage.
**Trade-off**: Limited to single-writer. If concurrent manager edits become a bottleneck, migrate to PostgreSQL later (Ecto makes this straightforward).

### Phoenix-served SPA over separate containers
**Decision**: Vue builds into `priv/static/`, Phoenix serves everything.
**Why**: One container, one port, simpler deployment, no CORS config needed, no nginx/proxy layer. Phoenix is already excellent at serving static files.
**Trade-off**: No hot module reload during frontend dev without workaround. Acceptable for Docker-only workflow.

### Non-umbrella Phoenix app
**Decision**: Standard Phoenix app, not umbrella.
**Why**: KISS. Single app with well-separated contexts is sufficient for this scope. Umbrella adds complexity without benefit here.

### ueberauth for Microsoft OAuth
**Decision**: Use ueberauth + ueberauth_microsoft.
**Why**: Well-maintained, standard Elixir approach. Plugs-based, integrates naturally with Phoenix auth pipeline. Avoids custom OAuth implementation.

### SVG radar chart over charting library
**Decision**: Custom SVG rendering in Vue, no D3 or Chart.js.
**Why**: Radar chart math is straightforward (polar coordinates). Custom SVG gives full control over styling to match Figma design. No dependency bloat. Easier to test.

### archgate/cli for pipeline rules
**Decision**: Use archgate to encode ADRs as executable checks.
**Why**: ADRs become living documents backed by automated enforcement. Integrates with pre-commit and CI. Free tier is sufficient.

---

*This document is updated as new decisions and learnings emerge during development.*
