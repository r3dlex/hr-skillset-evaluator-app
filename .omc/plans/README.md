# `.omc/plans/` — approved OMC plans for SkillForge

Approved **ralplan** (or other OMC planning workflow) outputs scoped
to the hr-skillset-evaluator-app subrepo. These are durable records
of how the work described in `.omc/specs/` was approved and
sequenced.

Mirrors the rib-workspace convention (see
`r3dlex/rib-workspace/.omc/plans/`).

## When to write here

- A **ralplan** consensus approved in a subrepo-scoped session
- Any other OMC planning artifact that documents a SkillForge
  workstream end-to-end (problem, options considered, chosen path,
  consensus, follow-ups)

## What does NOT belong here

- Cross-workspace plans affecting other subrepos — those go in
  `r3dlex/rib-workspace/.omc/plans/`
- Transient session state (`.omc/state/`)
- Implementation logs (`.omx/logs/`)
