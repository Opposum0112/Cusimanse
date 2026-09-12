# 05 — Multi-Agent Operating Model

![Experiment workflow](ai-security-lab-experiment-workflow.png)

## Structured roles

```text
Planner → Researcher → Security Reviewer → Executor
                                      ↓
                               Forensics → Verifier → Reporter
```

Goose is the **primary operator, executor and lifecycle orchestrator**. Roles are configuration, not separate project controllers.

An optional CrewAI integration can coordinate role-based specialist agents for research analysis. CrewAI operates inside the declared Cusimanse orchestration contract and returns structured results to Goose; it does not replace Goose or the VM/cloud security boundary.

| Role | Responsibility |
|---|---|
| Planner | objective, hypothesis, success criteria |
| Researcher | expected behavior and instrumentation |
| Reviewer | safety, policy, prerequisites, approval |
| Executor | approved VM/workload operations through Goose |
| Forensics | evidence reduction and analysis |
| Independent reviewer | challenge findings independently |
| Reporter | reproducibility and findings |

## Optional CrewAI orchestration

The CrewAI integration is declared in `recipes/orchestration/crewai.yaml`. It may provide specialist roles such as researcher, runtime analyst, forensics analyst, detection analyst, verifier and reporter.

```text
Cusimanse contract
       ↓
     Goose
       ↓
   CrewAI Crew
       ├── Researcher
       ├── Runtime Analyst
       ├── Forensics
       ├── Detection Analyst
       └── Verifier
       ↓
 structured role results
       ↓
     Goose
       ↓
 VM/cloud execution and evidence lifecycle
```

Activation is policy-controlled with `policyctl check --action crew-orchestration`. CrewAI is optional; unavailable capability is recorded as `NOT_DEPLOYED`.

## Handoffs

Use structured artifacts under `blackboard/` rather than copying long conversations between agents.

## Capability selection

MCP, skills, tools and optional orchestration frameworks are selected from their registries. Every material selection is written to the audit record.

## Independence

The verifier must be able to reject the primary agent or crew conclusion. It must not inherit an unverified claim as fact.
