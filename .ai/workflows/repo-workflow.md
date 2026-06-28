# Repository workflow

This repository follows the AI-SDLC v3 workflow.

## Required phases

1. Discover and Decide: classify topology, host posture, and repo boundaries.
2. Govern and Plan: keep `AGENTS.md`, `RULES.md`, `PLANS.md`, ADRs, specs, and work intake aligned.
3. Configure and Generate: keep `.ai/`, `.memory/`, command manifests, and policy checklists current.
4. Validate and Handoff: run local validation, reconcile hosted state, and record handoff evidence.

## Merge gate

Merge only after the architect, reviewer, and executor loop agrees, actionable PR comments are resolved, local validation is green, and hosted SCM CI is green.

## Host policy boundary

Branch protection, rulesets, approval policy, and other hosted policy mutations stay checklist-only until explicitly confirmed by an operator with admin authority.
