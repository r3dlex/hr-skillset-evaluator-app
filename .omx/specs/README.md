# `.omx/specs/` — OMX test and acceptance specs for SkillForge

Test specifications, acceptance criteria, and escalation-signal
definitions scoped to the hr-skillset-evaluator-app subrepo. These
are downstream-of-OMC artifacts that turn an approved plan into
executable test plans.

Mirrors the rib-workspace convention (see
`r3dlex/rib-workspace/.omx/specs/`).

## When to write here

- A test-spec that operationalizes a `.omx/plans/` PRD
- An escalation-signal definition (CI/CD, observability)
- An acceptance-criteria document for a feature

## Companion artifacts

Every spec here should trace back to a plan in
[`.omx/plans/`](../plans/).
