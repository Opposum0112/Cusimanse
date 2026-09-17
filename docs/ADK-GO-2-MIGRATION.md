# ADK Go 2 Migration

`adk-cusimanse` is the native Go evolution path for Cusimanse. It is intentionally isolated from every other repository and branch.

## Architecture contract

- **ADK Go 2:** reasoning, planning, workflow graph, tool calling, HITL, session state, memory and artifacts.
- **Cusimanse Go:** contracts, requirements, capability registry, policy, authorization, execution limits, evidence and audit.

**The agent decides what to research. Cusimanse decides what may execute.**

## Completed increment

- Go 1.25 baseline and ADK v2 dependency.
- Native Go ADK runtime and terminal entry point.
- Capability request tool bridged to the existing Go registry/policy engine.
- Fail-closed capability lookup.
- `Check()` before `Execute()`.
- ADK session and memory services for development.
- Atomic durable Cusimanse execution journal.
- Terminal resume visibility and per-turn durable checkpoints.
- Legacy Goose-specific agent/recipe scaffolding removed from this branch.
- End-user architecture and migration documentation.

## Next implementation increments

### 1. Graph-native adaptive research loop

Express the complete research lifecycle as an ADK Go 2 graph:

```text
INTAKE → CONTRACT/REQUIREMENTS → PLAN → CAPABILITY RESOLUTION
                                      ↓
                                  POLICY GATE
                              ↙       ↓        ↘
                           DENY     HITL       ALLOW
                             ↓       ↓           ↓
                           REPLAN  PAUSE       EXECUTE
                                              ↓
                                     OBSERVE → ANALYZE
                                                ↓
                                             VERIFY
                                                ↓
                                       ACCEPTANCE CHECK
                                         ↙           ↘
                                      GAP             PASS
                                       ↓               ↓
                                  bounded replan   PRESERVE
                                                       ↓
                                                    REPORT
                                                       ↓
                                                 DESTROY LAB
```

Use ADK graph routing, bounded loops, retries/timeouts and parallel workers where they improve research throughput. Do not introduce another orchestration framework.

### 2. Persistent ADK sessions

Replace the development in-memory session service with a persistent implementation so a paused/interrupted graph can resume from its workflow checkpoint after process restart. Keep `internal/state` as the crash-recovery/audit envelope.

### 3. Persistent memory and artifacts

Separate the data planes:

| Plane | Responsibility |
|---|---|
| ADK session | Mutable workflow state |
| ADK memory | Searchable long-term research context |
| ADK artifacts | Versioned research outputs |
| Cusimanse evidence | Authoritative observations and provenance |
| Cusimanse journal | Recovery and audit envelope |

Memory is advisory; preserved evidence is authoritative.

### 4. Provider-neutral model factory

Keep model selection behind a Go factory. Gemini is the initial adapter. Add Google, OpenAI-compatible, Anthropic, DeepSeek and local/gateway transports without changing capability or policy contracts. LiteLLM/OmniRoute can be treated as optional OpenAI-compatible gateway transports.

### 5. Capability contract hardening

Every capability should define a stable ID/version, typed input schema, preconditions, risk class, authorization requirements, timeout/resource limits, `Check()`, `Execute()`, evidence output, idempotency semantics and cleanup behavior.

The model can request a capability but cannot bypass these controls.

### 6. Recovery and replay

Add deterministic run IDs, invocation IDs and idempotency keys. Explicitly model `NOT_STARTED`, `PENDING_APPROVAL`, `RUNNING`, `COMPLETED`, `FAILED`, `AMBIGUOUS_EFFECT`, `PRESERVED` and `CLEANUP_PENDING`. Recovery must revalidate before repeating side effects.

### 7. Production single binary

Target one native Go binary with terminal operation, structured output, durable sessions, policy enforcement, capability providers and optional API/A2A surfaces. Python, LangGraph and Goose must not become runtime dependencies.

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

## Non-goals

- No Python agent runtime in this branch.
- No LangGraph dependency.
- No Goose orchestration dependency.
- No parallel policy authority.
- No direct host execution from the LLM.
- No credentials embedded in prompts, recipes or evidence.

## Validation gate

A production increment requires deterministic tests covering authorization, policy enforcement, HITL pause/resume, state recovery, memory/artifact separation, evidence provenance, idempotency and cleanup behavior.
