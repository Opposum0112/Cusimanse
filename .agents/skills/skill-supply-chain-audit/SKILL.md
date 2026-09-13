---
name: skill-supply-chain-audit
description: Audit external agent skills for provenance, permissions, scripts, network behavior, dependencies, licensing, and supply-chain risk before deployment.
---

# Skill supply-chain audit

## Workflow
1. Identify the canonical upstream repository and exact revision.
2. Inspect `SKILL.md`, scripts, references, templates, binaries, and dependency manifests.
3. Enumerate tool calls, filesystem writes, network destinations, credentials, environment variables, and subprocess execution.
4. Check license, maintainer provenance, release history, and integrity where available.
5. Classify the skill as `approved`, `candidate-review-required`, `rejected`, or `NOT_DEPLOYED`.
6. Record the decision and source revision in the skill registry and audit trail.

## Rules
- Registry presence does not imply trust.
- A skill cannot grant privileges or weaken VM/OS controls.
- Never execute an unreviewed skill merely to inspect it.
- Public services must never receive private workload data or secrets.
- Missing provenance or unavailable source means `NOT_DEPLOYED`.
