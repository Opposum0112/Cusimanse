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

## Prompt library and handoff

The canonical agent-neutral handoff is `prompts/experiments/<experiment>.md`. If a researcher selects an operator other than Goose, that operator must receive the same experiment prompt plus its operator-specific guide under `prompts/operators/`. The adapter matrix `recipes/agents/adapter-matrix.yaml` defines these references.

The handoff contains intent/workflow context and file references. It does **not** authorize execution. The contract, experiment configuration and trusted recipes remain the sources of truth; the Go capability API and policy remain the execution authority.

```text
contract + experiment requirements
              ↓
shared experiment prompt
              ↓
selected operator
  ├── Goose native + Summon
  └── alternate adapter + operator guide
              ↓
      Cusimanse Go runtime
              ↓
       policy + trusted plan
              ↓
       disposable capability
              ↓
             evidence
              ↓
       specialist analysis
```

## Goose and Summon

Goose is the native reference agent. Summon provides delegation to specialist subagents. Delegation is an intelligence/orchestration mechanism, not an alternative execution authority.

A specialist should request a registered capability rather than invoke a host shell directly.

## Other agents

OpenCode, Hermes, Antigravity and Pi are supported adapter candidates. Their shared experiment prompt and operator guides establish the same boundary: native tools may be used for planning and analysis, but capability execution remains inside Cusimanse. An adapter must record unavailable capabilities as `PARTIAL` and cannot create trusted profiles, mutate recipes/policy, widen authority or execute the workload directly on the host.

An adapter is not considered deployed until runtime evidence demonstrates that it respects this boundary and independent verification passes.