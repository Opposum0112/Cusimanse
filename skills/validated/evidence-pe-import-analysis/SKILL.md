---
name: evidence-pe-import-analysis
description: Analyze PE imports for suspicious API patterns using deterministic tooling.
risk_tier: low
tools:
  - python3
  - file
  - objdump
tags:
  - malware-analysis
  - static-analysis
status: CANDIDATE
---

# PE import analysis

This package is an **example learning target**, not a pre-approved security capability. It demonstrates the package layout used by the Architecture Refactor branch.

## Procedure

1. Verify the artifact identity and provenance.
2. Run the deterministic analysis script inside the approved research environment.
3. Preserve stdout, stderr and tool metadata as evidence.
4. Compare the result with the case hypothesis.
5. Independently verify important findings.

## Promotion requirements

Do not mark this skill `VALIDATED` until the evidence-bounded promotion contract is satisfied: two validated cases on distinct artifacts, replay, independent verification, provenance and human approval.

## Safety

This skill must not request host-root mounts, credentials, unrestricted host execution or public MCP exposure.
