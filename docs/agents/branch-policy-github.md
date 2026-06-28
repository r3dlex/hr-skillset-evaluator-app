# GitHub branch policy checklist

- Default branch: `main`.
- Require PR before merge.
- Disallow direct pushes to protected `main`.
- Require local validation and hosted CI checks.
- Require architect, reviewer, and executor agreement.
- Require actionable comments to be resolved.
- Administrator bypass is allowed only when host policy permits it and the actor, authority, reason, checks, and approval mode are recorded.
- Hosted branch policy mutation is checklist-only here. Do not call GitHub APIs to change rulesets without explicit confirmation.

References:
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches
