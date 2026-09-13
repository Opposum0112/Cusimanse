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
Every agent/model/tool session should emit token usage when available: session ID, agent, model, input tokens, output tokens, tool-call count, cache usage, estimated cost, and optimization notes. Token accounting is observability only and cannot authorize actions.
