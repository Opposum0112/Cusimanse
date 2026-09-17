# ADK Go 2 Migration

`adk-cusimanse` is the native Go evolution path for Cusimanse. It is intentionally isolated from every other repository and branch.

## Architecture contract

- **ADK Go 2:** reasoning, planning, workflow graph, tool calling, HITL, session state, memory and artifacts.
- **Cusimanse Go:** contracts, requirements, capability registry, policy, authorization, execution limits, evidence and audit.

**The agent decides what to research. Cusimanse decides what may execute.**

## Completed on this branch

- Go 1.26.6 module baseline.
- `google.golang.org/adk/v2` v2.4.0 dependency.
- Native Go ADK terminal agent.
- Capability requests bridged to the existing Go registry/policy engine.
- Fail-closed capability lookup.
- `Check()` before `Execute()`.
- ADK session/memory integration.
- Database-backed ADK session persistence for restartable sessions.
- Atomic Cusimanse durable execution journal.
- Terminal session IDs and durable checkpoints.
- Legacy Goose-specific agent scaffolding removed.
- End-user testing and architecture documentation.

## Remaining hardening

### 1. Graph-native adaptive research loop

Complete the research graph as:

```text
INTAKE → REQUIREMENTS → PLAN → CAPABILITY REQUEST
                                  ↓
                              POLICY GATE
                           ↙      ↓       ↘
                        DENY    HITL      ALLOW
                           ↓      ↓          ↓
                        REPLAN  PAUSE      CHECK
                                             ↓
                                          EXECUTE
                                             ↓
                                      OBSERVE → ANALYZE
                                                  ↓
                                               VERIFY
                                                  ↓
                                           ACCEPTANCE
                                           ↙         ↘
                                        GAP           PASS
                                         ↓             ↓
                                   bounded replan   PRESERVE
                                                        ↓
                                                     REPORT
                                                        ↓
                                                     CLEANUP
```

Use ADK graph routing, bounded loops, retries/timeouts and parallel workers only where they improve research throughput without weakening the security boundary.

### 2. Persistent memory and artifacts

Make long-term research memory and artifact storage durable and explicitly separate from authoritative evidence.

| Plane | Responsibility |
|---|---|
| ADK session | Mutable workflow state |
| ADK memory | Searchable reusable context |
| ADK artifacts | Versioned agent outputs |
| Cusimanse evidence | Authoritative observations/provenance |
| Cusimanse journal | Recovery/audit envelope |

### 3. Provider-neutral model factory

Keep model selection behind a Go factory. Gemini is the initial adapter. Future OpenAI-compatible, Anthropic-compatible and local/gateway transports must not alter capability or policy contracts.

LiteLLM/OmniRoute may be optional transport/routing layers; neither is a security authority.

### 4. Capability contract hardening

Every executable capability should expose a stable ID/version, typed input/output, preconditions, risk class, authorization requirements, limits, `Check()`, `Execute()`, evidence hooks and explicit idempotency/cleanup semantics.

### 5. Recovery, replay and idempotency

Add deterministic run IDs, invocation IDs and idempotency keys. Explicitly handle:

`NOT_STARTED`, `PENDING_APPROVAL`, `RUNNING`, `COMPLETED`, `FAILED`, `AMBIGUOUS_EFFECT`, `PRESERVED`, `CLEANUP_PENDING`.

Never blindly replay a potentially side-effecting operation.

### 6. Production single binary

Target one native Go binary with terminal operation, structured output, durable sessions, policy enforcement, capability providers and optional API/A2A surfaces. Python, LangGraph and Goose remain outside this runtime.

## Security invariants

1. The LLM never receives a raw shell-execution primitive.
2. Unknown capabilities fail closed.
3. Policy is evaluated independently of model output.
4. HITL cannot override an absolute policy denial.
5. `Check()` always precedes `Execute()`.
6. Credentials never belong in prompts, recipes or evidence.
7. Observations are not silently promoted to verified findings.
8. Destructive lab actions use explicit lifecycle controls.
9. Recovery is conservative and idempotent where possible.
10. Evidence provenance survives model-provider changes.

## Validation gate

Before calling the branch production-ready, tests should cover:

- capability lookup and authorization;
- policy denial and approval paths;
- HITL pause/resume;
- durable session recovery;
- memory/artifact/evidence separation;
- evidence provenance;
- bounded research-loop termination;
- idempotent/replay-safe execution;
- ambiguous-effect recovery;
- disposable-lab cleanup.

## Non-goals

- No Python agent runtime.
- No LangGraph dependency.
- No Goose orchestration dependency.
- No competing policy authority.
- No direct host execution from the LLM.
- No credentials embedded in prompts, recipes or evidence.
