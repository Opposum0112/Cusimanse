# 05 — Multi-Agent Operating Model

![Experiment workflow](ai-security-lab-experiment-workflow.png)

## Structured roles

```text
Planner → Researcher → Security Reviewer → Executor
                                      ↓
                               Forensics → Verifier → Reporter
```

Goose hosts the agentic workflow. Roles are configuration, not separate controllers. Optional orchestration frameworks may coordinate specialist roles only within the declared contract.

| Role | Responsibility | Typical skills |
|---|---|---|
| Planner | objective, hypothesis, success criteria | experiment-planning, workload-triage |
| Researcher | expected behavior and instrumentation | static-analysis, threat-intelligence, vulnerability-research |
| Reviewer | safety, policy, prerequisites, approval | project-audit, independent-verification |
| Executor | approved VM/workload operations | experiment-run, dynamic-analysis, network-analysis |
| Forensics | evidence reduction and analysis | forensics, ioc-extraction, malware-analysis |
| Detection analyst | convert verified behavior into detections | detection-engineering, attack-mapping |
| Independent reviewer | challenge findings independently | independent-verification |
| Reporter | reproducibility and findings | research-reporting, evidence-reduction |

## Skill and MCP selection

Skills are selected from `recipes/skills/registry.yaml`. MCP integrations are selected from `recipes/mcp/registry.yaml`. Tool availability is declared by `recipes/tools/security-research.yaml`.

The selection order is:

`Contract → skills → tools → MCP → policy → approval → execution`

Every material selection and use is recorded in the audit layer. Unknown or unavailable capabilities are `NOT_DEPLOYED`.

## Security research reference data

Approved reference sources are catalogued in `recipes/reference/security-research-databases.yaml`. The catalog covers ATT&CK, CVE/NVD, CISA KEV/advisories, OWASP, Sigma, YARA, Suricata and selected community enrichment sources.

Reference data is **enrichment, not evidence**. Record source, retrieval time and confidence; independently verify important findings.

## MCP boundaries

MCP may expose repository inspection, evidence queries, controlled VM lifecycle, policy checks, telemetry and read-only public reference enrichment. Public MCP exposure is denied by default. Secrets and private workload data must never be sent to public reference services.

## Handoffs

Use structured artifacts under `blackboard/` rather than copying long conversations between agents. Preserve raw evidence before deterministic reduction.

## Independence

The verifier must be able to reject the primary agent's conclusion. A second LLM opinion is not sufficient independent evidence.
