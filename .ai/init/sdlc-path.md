# AI SDLC path

Repository `hr-skillset-evaluator-app` uses the brownfield v3 AI-SDLC adoption path.

- Topology: `standalone`.
- Sync strategy: physical-copy.
- Host posture: GitHub PR-only delivery with branch policy documented as checklist-only.
- Hosted branch and policy mutation: blocked unless an operator gives explicit confirmation.
- Application boundary: `application/` is excluded from umbrella initialization and follows `application/AGENTS.md`.
