# A2A handoff convention

Every handoff envelope includes `correlation_id`, `from_agent`, `to_agent`, `task`, `context_refs`, and `constraints`.

The handoff-envelope stores pointers, not secrets or large copied context. Receivers preserve `correlation_id` in their validation evidence.
