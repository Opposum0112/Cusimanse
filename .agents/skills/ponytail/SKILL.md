---
name: ponytail
description: Apply minimal-change and context-reduction practices inspired by Ponytail-style token optimization; use only for reducing redundant agent work, never for bypassing security controls.
---

# Ponytail integration

Use this skill when an agent is producing excessive context, repeated tool calls, or unnecessary generated artifacts.

## Practices
- compress repetitive context into short structured summaries
- reuse artifact IDs, hashes, and previously validated results
- avoid duplicate searches and duplicate analysis passes
- request only the fields needed from tools
- prefer deterministic local transformations for large evidence sets
- preserve the original evidence separately from reduced context

## Security invariant
Optimization must never remove policy, audit, approval, evidence, or independent-verification steps. Ponytail is an optimization aid, not a security boundary.

## Availability
Cusimanse records Ponytail as an optimization capability. If the upstream executable/package is unavailable, the skill remains usable as guidance and the software capability is `NOT_DEPLOYED`.
