# 05 — Multi-Agent Operating Model

![Experiment workflow](ai-security-lab-experiment-workflow.png)

## Structured roles

```text
Planner → Researcher → Security Reviewer → Executor
                                      ↓
                               Forensics → Verifier → Reporter
```

Goose hosts the agentic workflow. Roles are configuration, not separate controllers.

| Role | Responsibility |
|---|---|
| Planner | objective, hypothesis, success criteria |
| Researcher | expected behavior and instrumentation |
| Reviewer | safety, policy, prerequisites, approval |
| Executor | approved VM/workload operations |
| Forensics | evidence reduction and analysis |
| Independent reviewer | challenge findings independently |
| Reporter | reproducibility and findings |

## Handoffs

Use structured artifacts under `blackboard/` rather than copying long conversations between agents.

## Capability selection

MCP and skills are selected from their registries. Every material selection is written to the audit record.

## Independence

The verifier must be able to reject the primary agent's conclusion. It must not inherit an unverified claim as fact.
