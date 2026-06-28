# Deepen HR LLM streaming Adapter seam

## Northstar finding

    Move provider-specific SSE parsing and stream error mapping out of ChatController into LLM stream Modules with explicit Adapter behavior.

    ## Architecture contract

    - Module: selected repo-local architecture Module named in the plan.
    - Interface: the caller-facing seam will be smaller and explicit.
    - Implementation: duplicated or provider-specific behavior moves behind the seam.
    - Depth: more behavior becomes available behind a smaller Interface.
    - Adapter: concrete runtime behavior remains replaceable where variation exists.
    - Leverage: tests exercise the Interface instead of duplicating setup.
    - Locality: future changes concentrate in one Module.

    ## Planned files

    - `backend/lib/skillset_evaluator_web/controllers/chat_controller.ex`
- `backend/lib/skillset_evaluator/llm/provider.ex`
- `backend/lib/skillset_evaluator/llm/stream.ex`
- `backend/lib/skillset_evaluator/llm/anthropic_stream_adapter.ex`
- `backend/test/skillset_evaluator/llm/stream_adapter_test.exs`
- `.archgate/adr/006-llm-streaming-adapter-interface.md`

    ## Acceptance checks

    - `cd backend && mix test`
- `cd backend && mix format --check-formatted`
- `cd frontend && npm test`
- `python3 .ai/bin/validate-ai-sdlc.py`

    ## Autobahn gates

    - One PR for this issue.
    - Architect, code-reviewer, and executor loop completed.
    - Local validation green.
    - GitHub CI green.
    - Issue closed only after merge.
