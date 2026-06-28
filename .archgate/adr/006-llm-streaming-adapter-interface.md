# ADR-006: LLM Streaming Adapter Interface

## Status

Accepted

## Context

Chat streaming uses provider SSE payloads and provider-specific error shapes. Keeping that parsing in `ChatController` made the controller depend on Anthropic event names, token usage fields, and status-code mapping. That spread provider behavior into the web layer and made future provider changes harder to test.

## Decision

LLM providers that support streaming must return a stream config with an explicit adapter module. The web controller delegates streaming transport, SSE chunk parsing, token usage accumulation, and stream error formatting to `SkillsetEvaluator.LLM.Stream` and the configured adapter.

### Rules

- `ChatController` owns HTTP response compatibility and message persistence only.
- Provider-specific SSE event parsing lives in provider adapter modules.
- Provider-specific stream error mapping lives in provider adapter modules.
- Stream configs for supported streaming providers must include `:adapter`.
- `SkillsetEvaluator.LLM.Stream` is the provider-neutral runner for stream transport and chunk forwarding.
- Non-streaming providers may continue returning `{:error, reason}` from `stream/2` and use the existing fallback path.

### Enforcement

- Add focused tests for adapter parsing, adapter error mapping, and missing adapter failure.
- Keep controller streaming tests focused on external HTTP compatibility and persisted assistant messages.
- Prefer adding provider adapters over adding provider-specific branches to `ChatController`.

## Consequences

- Anthropic SSE parsing and error mapping are replaceable without editing the controller.
- Future providers can add streaming by implementing the adapter callbacks and returning the adapter in their stream config.
- The public chat HTTP behavior remains compatible while the internal streaming seam becomes smaller and easier to test.
