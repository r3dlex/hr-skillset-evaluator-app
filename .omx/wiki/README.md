# `.omx/wiki/` — OMX execution-time wiki for SkillForge

Execution-time knowledge base: the runbooks, observed behavior, and
operational notes that the OMX workflow accumulates while
SkillForge is being deployed, monitored, and supported.

This is the OMX sibling of the OMC planning-time
[`.omc/wiki/`](../omc/wiki/README.md).

## What goes here

- **Runbooks** — how to deploy, roll back, hotfix; the
  `docker compose up --build` cycle
- **Operational notes** — observed Elixir/Phoenix quirks,
  SQLite WAL mode behavior, archgate cache invalidation gotchas
- **Performance baselines** — Phoenix request latency, Vue bundle
  sizes, Ecto query timings
- **Incident postmortems** — what broke, root cause, prevention
- **Migration playbooks** — Elixir/Phoenix major version upgrades,
  Vue/Vite upgrades

## What does NOT belong here

- OMC-level knowledge (use [`.omc/wiki/`](../omc/wiki/))
- Transient logs (`.omx/logs/`)
- Live runtime state (`.omx/runtime/`, `.omx/state/`)
