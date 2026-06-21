# `.omx/plans/` - OMX plans for SkillForge

PRDs (product requirements documents) and other OMX planning
artifacts scoped to the hr-skillset-evaluator-app subrepo. OMX
plans are the durable, downstream-of-OMC counterpart to
[`.omc/plans/`](../omc/plans/README.md): once a workstream is
approved at the OMC level, the OMX plan records the executable
specification, acceptance criteria, and test plan.

Mirrors the rib-workspace convention (see
`r3dlex/rib-workspace/.omx/plans/`).

## When to write here

- A PRD generated from an approved `.omc/plans/` artifact
- A test-spec scoped to a SkillForge feature
- A ralplan handoff that bridges OMC and the implementation

## What does NOT belong here

- OMC-level plans (use [`.omc/plans/`](../omc/plans/))
- Session state (`.omx/state/`)
- In-flight debug notes (`.omx/logs/`)
