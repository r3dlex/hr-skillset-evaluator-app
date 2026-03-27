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

### Broadway for xlsx import pipeline
**Decision**: Use Broadway (with `Task.async_stream` for the synchronous path).
**Why**: Broadway provides the concurrency model for processing person rows in parallel during xlsx import. For the current synchronous import (single request), `Task.async_stream` with `max_concurrency: System.schedulers_online()` gives adequate parallelism. The Broadway callbacks are implemented and ready for a future async mode if needed.
**Trade-off**: Broadway dependency adds some weight but is well-maintained and provides a clear upgrade path to async processing.

### Native CI over pipeline-runner-in-Docker for test/lint
**Decision**: GitHub Actions runs backend tests (Elixir) and frontend tests (Node) natively instead of inside the pipeline-runner container.
**Why**: The pipeline-runner container has Python + Node but not Elixir. Running `mix test` inside it would require a much larger image with all three runtimes. Native CI with `erlef/setup-beam` and `actions/setup-node` is faster and simpler.
**Trade-off**: Local and CI pipelines are not identical. Pipeline runner is used for security scans and archgate checks locally.

### File-based SQLite test database over in-memory
**Decision**: Tests use `/tmp/skillset_evaluator_test.db` instead of `:memory:`.
**Why**: ecto_sqlite3 in-memory databases have limitations with concurrent access and the Ecto sandbox. A file-based test DB is more reliable and closer to production behavior.
**Trade-off**: Slightly slower test setup, but negligible at current test count.

### Anthropic over MiniMax as primary LLM
**Decision**: Use Claude (Anthropic) as primary, MiniMax as optional Chinese fallback.
**Why**: Claude handles EN/DE/ZH well. Provider abstraction layer allows adding providers later.
**Trade-off**: Requires internet connectivity for chat. Glossary-only fallback mode when API is unreachable.

### SSE over WebSocket for chat streaming
**Decision**: Server-Sent Events for chat response streaming.
**Why**: Simpler than WebSocket. Unidirectional (server -> client). No Phoenix Channels needed. Standard HTTP.
**Trade-off**: No bidirectional streaming. Acceptable since user sends discrete messages, not continuous input.

### Dual theme system (Default + RIB)
**Decision**: CSS variables for theming with two presets.
**Why**: Company branding requirement. CSS vars allow runtime switching without rebuild.
**Trade-off**: Slightly more complex CSS. Mitigated by centralized theme store.

### Collapsible sidebar
**Decision**: Sidebar docks to icons-only strip (64px) with tooltips.
**Why**: Maximizes content area on smaller screens. Common UX pattern.

---

*This document is updated as new decisions and learnings emerge during development.*
