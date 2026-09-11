# 01 — Deployment Architecture

## Target architecture

```text
Human / CI
    |
    v
Markdown contracts
    |
    v
recipes/goose/project.yaml
    |
    v
GOOSE — orchestrator + operator + executor
    |
    +-- modular recipes: experiment / workload / install / host / VM / tools
    |                     instrumentation / monitoring / agents / orchestration
    |                     routing / stages / reporting / token dashboard
    |
    +-- policyctl: host/security policy configuration only
    |
    v
Lima / QEMU disposable VM
    |
    v
workload + instrumentation
    |
    v
evidence -> deterministic reduction -> forensic agent -> independent verification
    |
    v
report / token dashboard / Git
```

## Architectural rules

1. Goose is the only project orchestrator/operator/executor.
2. YAML is the configuration and composition layer; `project.yaml` is an entry recipe, not a monolith.
3. `policyctl` is separate and only configures host/security policy.
4. No project execution controller is required alongside Goose.
5. Untrusted workloads execute only inside disposable VMs.
6. Evidence is preserved before destruction and independently verified.
7. Missing capabilities are reported as `NOT_DEPLOYED`.
