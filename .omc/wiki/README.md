# `.omc/wiki/` - subrepo-scoped OMC wiki

Persistent markdown knowledge base pages that compound across OMC
sessions working in the hr-skillset-evaluator-app subrepo. This is
the subrepo-scoped sibling of the OMC wiki that lives at
`r3dlex/rib-workspace/.omc/wiki/`.

## What goes here

- **Architecture notes** - diagrams (mermaid), module boundaries
 (Elixir/Phoenix context boundaries, Vue 3 component tree), key
 invariants
- **Decisions** - ADRs scoped to this subrepo (cross-cutting ADRs
 go in the workspace wiki, or in `.archgate/adr/` for code-shape
 decisions)
- **Patterns** - conventions specific to this subrepo (Phoenix
 contexts, Ecto schemas, Vue 3 composables, etc.)
- **Debugging** - known failure modes and how to triage them
- **Reference** - quick links to external systems (archgate,
 SQLite, the LLM provider, Docker)
- **Conventions** - style and naming rules unique to this subrepo

## What does NOT belong here

- Session-scoped working memory (`.omc/state/`, `.omc/sessions/`)
- Cross-workspace knowledge - go up to the workspace wiki
- Generated artifacts (logs, reports) - those go in `.omx/`
- Code-shape ADRs - those go in `.archgate/adr/`
