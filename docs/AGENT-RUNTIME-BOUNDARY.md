# Agent and runtime boundary

Cusimanse deliberately separates **research intelligence** from **execution authority**.

## Agent responsibilities

The primary agent (Goose) and delegated specialists may:

- understand the research objective and contract;
- generate hypotheses and investigation plans;
- select registered roles and Skills;
- request capabilities through the Cusimanse API;
- inspect observations and preserved evidence;
- decide whether another research step is useful;
- analyze, verify and report findings.

Agents may not turn model output into trusted infrastructure, broaden experiment scope, bypass policy, execute untrusted workloads on the host, or promote learned Skills without the required gates.

## Runtime responsibilities

Cusimanse owns:

- requirements and trusted-profile resolution;
- execution-plan construction;
- policy decisions and approval gates;
- capability registration and checks;
- disposable compute provisioning;
- workload execution and instrumentation;
- evidence collection, hashing and verification;
- preservation-before-destroy enforcement;
- runtime/session observability and provenance.

## Goose and Summon

Goose is the native reference agent. Summon provides delegation to specialist subagents. Delegation is an intelligence/orchestration mechanism, not an alternative execution authority.

A specialist should request a registered capability rather than invoke a host shell directly:

```text
Goose/Summon specialist
        ↓
capability request
        ↓
Cusimanse Go runtime
        ↓
policy + trusted execution plan
        ↓
disposable capability
        ↓
evidence
        ↓
agent analysis
```

## Other agents

OpenCode, Hermes, Antigravity and Pi are adapter candidates. Their prompts establish the same boundary: they can provide intent and analysis, but capability execution remains inside Cusimanse. An adapter is not considered deployed until runtime evidence demonstrates that it respects this boundary.
