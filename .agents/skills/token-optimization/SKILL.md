---
name: token-optimization
description: Reduce unnecessary agent context, tool calls, duplicated work, and generated output while preserving security evidence, auditability, and verification.
---

# Token optimization

## Optimize
- Prefer focused file reads and targeted searches over repeated full-repository reads.
- Reuse verified context and immutable identifiers instead of rediscovering them.
- Summarize stable evidence once, then reference its hash or artifact ID.
- Batch independent read-only operations when safe.
- Avoid repeating equivalent workflows or tool calls.
- Keep agent prompts and reports concise while preserving decision-critical evidence.

## Never optimize away
- security policy checks
- approval gates
- audit events
- evidence capture or hashes
- independent verification
- required provenance and source citations
- failure/`NOT_DEPLOYED` states

## Session accounting
Every agent/model/tool session should emit token usage when available: session ID, agent, model, input tokens, output tokens, tool-call count, cache usage, estimated cost, and optimization notes.

Start the localhost-only dashboard for a session with:

```bash
cusimanse-token-dashboard
```

The command is installed by the host installer under the observability/governance plane and uses `reports/token-usage/usage.json` by default. `policyctl token-dashboard` is the underlying policy-compatible dashboard interface. The dashboard is observability only: it cannot authorize execution, relax policy, or bypass the VM/OS boundary.

If an upstream optimization executable such as Ponytail, Numbat, or Miller is unavailable, record it as `NOT_DEPLOYED` and retain the declarative skill/recipe fallback. Installation must never silently replace a missing security control with an optimization tool.
