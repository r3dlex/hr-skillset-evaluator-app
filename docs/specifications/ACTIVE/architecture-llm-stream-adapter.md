# Deepen HR LLM streaming Adapter seam

    ## Issue

    https://github.com/r3dlex/hr-skillset-evaluator-app/issues/7

    ## Intent

    Move provider-specific SSE parsing and stream error mapping out of ChatController into LLM stream Modules with explicit Adapter behavior.

    ## Current friction

    The selected Module exposes too much Implementation detail to callers or duplicates the same contract across nearby Modules. This lowers Depth and spreads future fixes across more than one place.

    ## Target architecture

    - Keep the public Interface backward compatible unless an existing test proves a bug.
    - Move repeated behavior behind one repo-local seam.
    - Keep concrete runtime behavior in explicit Adapter code where variation exists.
    - Add focused tests at the Interface seam before or with the Implementation change.
    - Record the design decision in the repo architecture docs.

    ## Scope

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
