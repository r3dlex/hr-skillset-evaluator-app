# `.omc/specs/` — deep-interview and other input specs for SkillForge

Input specifications that seed OMC planning workflows scoped to the
hr-skillset-evaluator-app subrepo. A spec captures the problem
statement, scope, constraints, and success criteria **before** a
plan is generated.

Mirrors the rib-workspace convention (see
`r3dlex/rib-workspace/.omc/specs/`).

## When to write here

- A **deep-interview** transcript/spec produced from a SkillForge-
  scoped session
- Any other OMC input specification that grounds a subsequent
  `.omc/plans/` artifact in this subrepo

## Companion artifacts

Every spec here should have a corresponding plan in
[`.omc/plans/`](../plans/) that references it (typically via
`spec_ref:` in the plan frontmatter).
