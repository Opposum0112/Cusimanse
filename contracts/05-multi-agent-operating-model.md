# 05 — Multi-Agent Operating Model

![Experiment workflow](../docs/images/cusimanse-workflow.png)

## Structured roles

```text
Planner → Researcher → Security Reviewer → Executor
                                      ↓
                               Forensics → Verifier → Reporter
```

The selected primary agent hosts the runtime operator workflow. Roles are configuration, not separate security controllers. Optional CrewAI orchestration may coordinate specialist roles inside the declared boundary.

| Role | Responsibility | Typical skills |
|---|---|---|
| Planner | objective, hypothesis, success criteria | workload-triage |
| Researcher | expected behavior and instrumentation | static-analysis, threat-intelligence, vulnerability-research |
| Reviewer | safety, policy, prerequisites, approval | project-audit, independent-verification |
| Executor | approved VM/workload operations | experiment-run, dynamic-analysis, network-analysis |
| Forensics | evidence reduction and analysis | forensics, ioc-extraction, malware-analysis |
| Detection analyst | convert verified behavior into detections | detection-engineering, attack-mapping |
| Independent reviewer | challenge findings independently | independent-verification |
| Reporter | reproducibility and findings | evidence-reduction |

## Skill and MCP selection

Skills are selected from `recipes/skills/registry.yaml`. MCP integrations are selected from `recipes/mcp/registry.yaml`. Tool availability is declared by `recipes/tools/security-research.yaml`.

Selection order:

`Contract → skills → tools → MCP → policy → approval → execution`

Every material selection and use is recorded in the audit layer. Unknown or unavailable capabilities are `NOT_DEPLOYED`.

## Optional CrewAI layer

CrewAI is a role-based coordination layer only. It cannot replace the selected primary agent, policy, approval, VM/OS enforcement, evidence preservation or independent verification.

## Reference data

Approved reference sources are catalogued in `recipes/reference/security-research-databases.yaml`. Reference data is enrichment, not evidence; record source, retrieval time and confidence and independently verify important findings.

## Handoffs and independence

Use structured artifacts under `blackboard/` rather than copying long conversations. Preserve raw evidence before deterministic reduction. The verifier must be able to reject the primary agent's conclusion; a second LLM opinion alone is not sufficient independent evidence.
