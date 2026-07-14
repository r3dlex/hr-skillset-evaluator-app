# Protected Edit Approvals

Protected edits require explicit approval before the first edit. The recommended
mode is one exact command per matched `(category, path)` pair:

```text
confirm-protected-edit <category> <relative-path>
```

## Optional block approval

A large protected set may use one block command after the complete canonical
manifest is shown:

```text
confirm-protected-edit-block <TICKET> <HEAD_SHA> <COUNT> <MANIFEST_SHA256>
```

The block command approves only the displayed manifest for the exact ticket and
Git HEAD. It is not a wildcard, prefix, category-wide grant, or an interpretation
of "approve all".

The canonical manifest uses these rules:

- UTF-8 without a byte-order mark.
- One `confirm-protected-edit <category> <relative-path>` line per matched pair.
- Exact duplicates removed.
- Lines sorted by the UTF-8 bytes of the complete line.
- LF line endings and one final LF.
- A lowercase SHA-256 over those exact bytes.

The approval consumer supplies the complete currently unapproved set to
`verify` immediately before acceptance. The verifier canonicalizes that set
again, resolves the repository HEAD itself, and rejects any ticket, HEAD,
count, hash, entry-set, or mid-verification HEAD mismatch. A manifest containing
`agent-config` must never use block approval. Agent configuration always
requires individual approval.

Each accepted block expands into one append-only audit record per manifest
entry before editing begins. Each record keeps the normal category, path, HEAD,
timestamp, and approver-phrase hash. It also records block mode, ticket,
manifest count, and manifest SHA-256. The audit destination is fixed inside the
worktree-specific Git metadata. A caller cannot select or redirect it. Symlink,
hard-link, non-regular-file, and Git-metadata manifest targets fail closed.

Use `.ai/bin/protected_edit_approval.py prepare` to produce a canonical manifest
and exact block phrase. Use `verify` to validate a supplied block phrase against
the current unapproved manifest and current HEAD, then append its per-entry audit
records to the fixed Git-metadata log before returning success. The one-by-one flow
remains the recommendation because it has the smallest approval scope.
