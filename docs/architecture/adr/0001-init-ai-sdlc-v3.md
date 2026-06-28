# ADR 0001: Adopt AI-SDLC v3

Status: accepted.

## Context

`SkillForge HR skillset evaluator` needs deterministic AI-assisted delivery governance across planning, implementation, review, validation, and handoff.

## Decision

Adopt the AI-SDLC v3 scaffold with physical-copy sync, checklist-only hosted policy changes, traceability, eval declarations, observability, MCP/A2A stubs, and an architect plus reviewer plus executor merge gate.

## Consequences

- Changes are routed through PRs.
- Local validation runs before completion claims.
- Hosted policy changes remain blocked until explicitly confirmed.
