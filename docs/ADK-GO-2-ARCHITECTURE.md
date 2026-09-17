# Cusimanse ADK Go 2 Architecture

## 1. Purpose

`adk-cusimanse` is the native Go evolution of Cusimanse into a single security research agent.

Google ADK Go 2 provides the agent runtime: reasoning, planning, workflow orchestration, tool calling, HITL, sessions, memory and artifacts. Cusimanse provides the security authority: contracts, requirements, capability resolution, policy, authorization, execution constraints, evidence and audit.

> **The agent decides what to research. Cusimanse decides what may execute.**

## 2. End-to-end architecture

```text
                         SECURITY RESEARCHER
                                  |
                                  v
                 +--------------------------------+
                 |       ADK Go 2 AGENT          |
                 |--------------------------------|
                 | intake                         |
                 | requirement understanding      |
                 | planning                       |
                 | adaptive research loop         |
                 | tool/capability requests      |
                 | HITL                           |
                 | session state                  |
                 | memory                         |
                 | artifacts                      |
                 +---------------+----------------+
                                 |
                         named capability
                              request
                                 |
                                 v
                 +--------------------------------+
                 |     CUSIMANSE AUTHORITY        |
                 |--------------------------------|
                 | contract validation             |
                 | requirement resolution         |
                 | capability registry            |
                 | policy / authorization         |
                 | approval rules                 |
                 | Check()                        |
                 | Execute()                      |
                 | evidence / provenance          |
                 | durable recovery journal       |
                 +---------------+----------------+
                                 |
                                 v
                 +--------------------------------+
                 |    CONTROLLED EXECUTION        |
                 |--------------------------------|
                 | Lima / QEMU / Docker           |
                 | workload                       |
                 | instrumentation                |
                 +---------------+----------------+
                                 |
                                 v
                 +--------------------------------+
                 | OBSERVE → ANALYZE → VERIFY     |
                 |          → PRESERVE            |
                 +--------------------------------+
```

ADK is therefore an **orchestration plane**, not a security authority. The model cannot turn text into an executable host operation.

## 3. Researcher workflow

A complete investigation follows these stages.

### Stage 1 — Intake

The researcher states the question and scope.

Example:

```text
Investigate whether this npm package performs unexpected
network activity during installation.
```

The agent identifies the target, constraints, desired evidence and completion criteria.

### Stage 2 — Requirements

The agent converts the question into testable requirements.

Example:

```text
R1: reproduce installation in an isolated environment
R2: capture process and network telemetry
R3: preserve package and relevant artifact hashes
R4: correlate activity with the installation window
R5: independently verify the proposed finding
```

Requirements prevent the agent from treating an interesting observation as a completed investigation.

### Stage 3 — Plan

The planner creates a bounded sequence of research actions.

```text
prepare disposable lab
    ↓
install workload
    ↓
instrument process + network activity
    ↓
collect telemetry
    ↓
analyze observations
    ↓
verify hypothesis
```

The plan is guidance. Every actual operation still goes through the capability authority.

### Stage 4 — Capability resolution

The agent requests a named capability instead of receiving unrestricted shell access.

```text
Agent: "I need network observation for this step."
             ↓
request_capability(observe_network, typed input)
             ↓
Cusimanse registry lookup
```

Unknown capability IDs fail closed.

### Stage 5 — Policy and approval

The authority evaluates the request independently of the model's wording.

```text
capability exists?
    ├─ no  → DENY
    └─ yes
         ↓
policy permits?
    ├─ no  → DENY
    └─ yes
         ↓
approval required?
    ├─ yes → HITL approval
    └─ no
         ↓
capability.Check()
         ↓
capability.Execute()
```

Human approval cannot override an absolute policy denial.

### Stage 6 — Controlled execution

The capability operates through a registered execution provider. Security experiments should use disposable compute.

```text
provision → configure → instrument → execute
```

The agent does not receive a mechanism for bypassing the execution boundary.

### Stage 7 — Observation and collection

The system collects telemetry and artifacts through capabilities.

Examples:

- process tree and command metadata;
- network connections and DNS activity;
- filesystem changes;
- logs;
- package metadata;
- cryptographic hashes.

Observed data is stored separately from model interpretation.

### Stage 8 — Analysis

The analyzer correlates observations with the research requirements.

```text
Observation:
  installer process opened a network connection.

Analysis:
  the connection occurred during the installation window and
  requires verification against the expected package behavior.
```

The first statement is an observation. The second is analysis.

### Stage 9 — Independent verification

The verifier checks whether the proposed finding is supported by preserved evidence and whether the acceptance criteria are met.

There are three useful outcomes:

```text
PASS → preserve + report + cleanup
GAP  → identify missing evidence → refine plan → next iteration
FAIL → record failure/limitation → stop or revise safely
```

The adaptive loop is bounded. An unresolved hypothesis cannot cause infinite execution.

### Stage 10 — Preserve and cleanup

Once the acceptance criteria are satisfied:

```text
verified result
     ↓
hash + provenance
     ↓
preserve evidence/artifacts
     ↓
generate report
     ↓
destroy disposable lab
```

Preservation happens before destructive cleanup.

## 4. Adaptive research loop

The target ADK graph is:

```text
INTAKE
  ↓
REQUIREMENTS
  ↓
PLAN
  ↓
CAPABILITY REQUEST
  ↓
POLICY GATE
  ├── DENY ─────────────→ SAFE REPLAN / STOP
  ├── APPROVAL ─────────→ HITL → CHECK
  └── ALLOW ────────────→ CHECK
                              ↓
                           EXECUTE
                              ↓
                           OBSERVE
                              ↓
                           ANALYZE
                              ↓
                           VERIFY
                              ↓
                    ACCEPTANCE CHECK
                       /            \
                    PASS             GAP
                     |                |
                  PRESERVE       REFINE PLAN
                     |                |
                  REPORT ←──── bounded iteration
                     |
                  CLEANUP
```

The graph must make state transitions explicit. A retry is not equivalent to a blind re-execution: recovery must first determine whether a previous operation may already have had an external effect.

## 5. State, memory, artifacts and evidence

These stores have different meanings and authority.

| Store | Purpose | Authority |
|---|---|---|
| ADK session state | current workflow state | ADK runtime |
| ADK memory | reusable research context | advisory |
| ADK artifacts | versioned agent outputs | controlled artifact plane |
| Cusimanse journal | crash/recovery status | Cusimanse |
| Evidence | observed, hashed, provenance-linked material | authoritative |
| Verified finding | conclusion supported by evidence | verification stage |

**Memory helps the agent remember; evidence lets the system prove.**

## 6. Skills vs capabilities

Skills and capabilities are intentionally different.

```text
Skill
  = how to investigate / what to look for

Capability
  = an authorized executable operation

Memory
  = reusable context

Evidence
  = authoritative observation
```

A skill document cannot grant execution authority, and memory cannot silently become evidence.

## 7. HITL model

HITL is used where a capability requires explicit researcher approval. The approval request should identify the operation, target, risk and relevant inputs.

The authority chain remains:

```text
ADK request
   ↓
Cusimanse policy
   ↓
HITL if required
   ↓
Check()
   ↓
Execute()
```

Approval is a gate, not a substitute for policy.

## 8. Durable execution and recovery

The branch maintains two durability concerns:

1. **ADK session durability** — preserves the agent's workflow/session context across process restarts.
2. **Cusimanse durable journal** — records the last known execution phase/status for recovery and audit.

Recovery must distinguish at least:

```text
NOT_STARTED
PENDING_APPROVAL
RUNNING
COMPLETED
FAILED
AMBIGUOUS_EFFECT
PRESERVED
CLEANUP_PENDING
```

For `AMBIGUOUS_EFFECT`, the agent must not simply run the operation again. It should inspect available evidence/state, revalidate policy and choose a safe recovery path.

## 9. Model-provider boundary

The model provider is an implementation detail of the ADK agent layer.

```text
                    ADK model interface
                           |
          +----------------+----------------+
          |                |                |
        Gemini      OpenAI-compatible   Local/gateway
                                      
          future providers can be added
          without changing policy/capability
```

LiteLLM or OmniRoute can be used as optional routing/gateway infrastructure. They do not become a security authority.

## 10. Security invariants

1. The LLM never receives unrestricted shell execution.
2. Unknown capabilities fail closed.
3. Policy is independent of model output.
4. HITL cannot override an absolute denial.
5. `Check()` precedes `Execute()`.
6. Credentials are never embedded in prompts, recipes or evidence.
7. Observations are not silently promoted to verified findings.
8. Disposable compute has explicit lifecycle controls.
9. Recovery is conservative and idempotent where possible.
10. Evidence provenance survives model/provider changes.

## 11. Architecture evolution

The branch is being hardened in this order:

1. native Go ADK agent and capability bridge;
2. graph-native adaptive research loop;
3. persistent sessions, memory and artifacts;
4. provider-neutral model factory;
5. deterministic invocation/idempotency and replay;
6. production single-binary packaging and execution providers.

No second orchestration framework is required or intended.
