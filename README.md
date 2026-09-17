# Cusimanse — Native Go Security Research Agent

> **Active branch: `adk-cusimanse`**

Cusimanse is evolving into a **single native Go security-research agent** using Google ADK Go 2 for reasoning and workflow orchestration, while the Cusimanse Go runtime remains the security authority.

**Simple rule:** the agent decides *what to research*; Cusimanse decides *what may execute*.

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

## What can I test right now?

You can run the agent from a terminal, give it a security-research question, and observe the research workflow. The current branch is an **engineering/test track**, not a production security platform.

Good first tests:

1. Ask the agent to explain how it would investigate a suspicious behavior.
2. Ask it to identify which Cusimanse capability it needs.
3. Request an operation that should be denied and verify that the Go policy boundary rejects it.
4. Run a harmless capability in the disposable research environment.
5. Stop and restart the process with the same `--session` ID and inspect the durable checkpoint.
6. Review the resulting evidence separately from the model's reasoning.

Do not point the experimental agent at production systems or provide real credentials.

## 1. Install

### Requirements

- Go **1.26.6+**
- Gemini API key for the current default model integration
- macOS or Linux recommended
- Optional: Lima/QEMU/Docker for disposable execution experiments

The repository CI validates the Go module and native Go test suite.

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout adk-cusimanse

go mod download
go test ./...
```

## 2. Configure a model

The first provider is Gemini through the official ADK Go integration.

```bash
export GOOGLE_API_KEY="your-key"
export CUSIMANSE_MODEL="gemini-2.5-flash"
```

Never put API keys in prompts, recipes, source files, evidence, or committed configuration.

## 3. Start the agent

```bash
go run ./cmd/cusimanse-agent
```

You will get an interactive prompt:

```text
Cusimanse ADK Go 2 security research agent
model=gemini-2.5-flash session=research-...
Type /exit to stop. Capability execution is always mediated by the Go policy boundary.
> 
```

Enter a research question and press Enter. Use `/exit` or `/quit` to stop.

For repeatable testing, give the session a stable name:

```bash
go run ./cmd/cusimanse-agent \
  --model gemini-2.5-flash \
  --session npm-threat-research-001 \
  --state-dir .cusimanse/state
```

### Useful options

| Option | Purpose | Example |
|---|---|---|
| `--model` | Override the model ID | `--model gemini-2.5-flash` |
| `--session` | Reuse a research session | `--session webshell-test-01` |
| `--state-dir` | Store durable execution checkpoints | `--state-dir .cusimanse/state` |
| `--approved` | Enable explicitly approval-gated policy actions | `--approved` |

Start without `--approved` for the safest policy-boundary test.

## 4. Try these test scenarios

### Test A — Research planning only

```text
> Explain how you would investigate a suspicious npm package installation without executing anything.
```

Expected behavior:

- the agent creates a research approach;
- it may identify capabilities it would need;
- no arbitrary shell execution is exposed to the model;
- the security authority remains outside the model.

### Test B — Capability resolution

```text
> I need to inspect an artifact from a disposable security lab. What capability should be requested and why?
```

Expected behavior: the agent reasons about the required operation and requests a registered capability rather than inventing an execution mechanism.

### Test C — Policy denial

Ask for an operation that is outside the configured policy or uses an unknown capability.

Expected behavior:

```text
LLM intent
  ↓
ADK tool request
  ↓
Cusimanse capability registry
  ↓
policy check
  ↓
DENIED
```

A model response saying an operation is allowed does **not** authorize it.

### Test D — Disposable workload

For a lab-only experiment, the intended lifecycle is:

```text
provision → configure → instrument → execute → observe → collect → destroy
```

Each mutating stage remains subject to the Go capability and policy boundary. Keep workloads disposable and isolated from the host.

### Test E — Durable session resume

Start a named session:

```bash
go run ./cmd/cusimanse-agent --session resume-demo
```

Ask a research question, then exit. Start it again with the same session:

```bash
go run ./cmd/cusimanse-agent --session resume-demo
```

The terminal should report the previously recorded durable phase/status. The branch also uses a persistent ADK session service so the ADK session is not tied only to process memory.

## 5. Understand the researcher workflow

The agent is designed to behave like a security researcher rather than a shell wrapper.

### Step 1 — Understand the question

The researcher gives a goal, for example:

```text
Investigate whether a package installation performs unexpected network activity.
```

The agent identifies the target, scope, constraints and expected evidence.

### Step 2 — Load requirements and research context

The agent uses session state, memory and applicable research guidance. Requirements define what must be demonstrated before the investigation can finish.

Example acceptance criteria:

```text
- package behavior reproduced in an isolated lab
- network activity captured
- process lineage recorded
- relevant artifact hashes preserved
- finding independently verified
```

### Step 3 — Build a research plan

The planner turns the goal into bounded steps:

```text
prepare lab
→ install workload
→ instrument process/network activity
→ collect telemetry
→ analyze behavior
→ verify hypothesis
```

The plan is adaptive. If evidence is insufficient, the agent can refine the next research step rather than blindly repeating the same operation.

### Step 4 — Resolve a capability

The model does not receive a generic `shell` tool.

Instead it asks for a named capability, such as:

```text
collect_artifact
observe_network
inspect_process
provision_lab
```

Cusimanse resolves that request against its registered capability catalog.

### Step 5 — Apply the security boundary

Before execution:

```text
capability exists?
       ↓ yes
policy permits it?
       ↓ yes
approval required?
       ↓
HITL approval when configured
       ↓
capability.Check()
       ↓
capability.Execute()
```

Unknown capabilities fail closed. Policy is evaluated independently of the LLM's answer.

### Step 6 — Execute in controlled compute

Approved capabilities operate through registered execution providers. For security experiments, the preferred target is disposable compute such as Lima/QEMU or another explicitly configured backend.

The agent does not decide how to bypass the sandbox.

### Step 7 — Observe and collect

Telemetry and artifacts are collected through capabilities. Useful observations can include process activity, network connections, files, logs and hashes.

The system keeps **observed data** distinct from **model interpretation**.

### Step 8 — Analyze

The analyzer correlates collected evidence against the research question and requirements.

Example:

```text
Observation: process X opened connection Y.

Analysis: connection Y occurred immediately after package install
and matches the expected investigation window.
```

The second statement is interpretation; the first is evidence.

### Step 9 — Independently verify

A separate verification stage checks whether the evidence actually supports the proposed finding and whether acceptance criteria are satisfied.

If evidence is incomplete:

```text
VERIFY → GAP → refine plan → collect more evidence → VERIFY
```

The loop is bounded so an unresolved investigation cannot run forever.

### Step 10 — Preserve, report and clean up

Once acceptance criteria are satisfied:

```text
verified finding
   ↓
preserve evidence + provenance
   ↓
generate report
   ↓
clean up disposable lab
```

Destroying the lab must not destroy the preserved evidence required to reproduce or audit the result.

## 6. Architecture in one picture

```text
                         SECURITY RESEARCHER
                                  |
                                  v
                    +---------------------------+
                    |       ADK Go 2 Agent       |
                    |---------------------------|
                    | Understand / Plan          |
                    | Adaptive research loop     |
                    | Tool calling               |
                    | HITL                       |
                    | Session state              |
                    | Memory / artifacts         |
                    +-------------+-------------+
                                  |
                           named capability
                                  |
                                  v
                    +---------------------------+
                    |    CUSIMANSE AUTHORITY     |
                    |---------------------------|
                    | Contracts / requirements   |
                    | Capability registry       |
                    | Policy / authorization    |
                    | Check / Execute boundary  |
                    | Evidence / provenance     |
                    | Durable audit state       |
                    +-------------+-------------+
                                  |
                                  v
                    +---------------------------+
                    |    CONTROLLED EXECUTION   |
                    |---------------------------|
                    | Lima / QEMU / Docker       |
                    | Instrumentation            |
                    | Workload                   |
                    +-------------+-------------+
                                  |
                                  v
                    +---------------------------+
                    | OBSERVATIONS / EVIDENCE    |
                    | Analyze → Verify → Preserve|
                    +---------------------------+
```

### Responsibility split

| Component | It does | It must not do |
|---|---|---|
| ADK Go 2 | reason, plan, route workflow, call tools, maintain agent context | authorize arbitrary execution |
| Cusimanse authority | validate contracts, resolve capabilities, enforce policy, authorize, execute, preserve evidence | follow model instructions blindly |
| Execution provider | run an explicitly authorized workload | become an alternate policy engine |
| Memory | retain useful research context | become authoritative evidence |
| Evidence ledger | preserve observations/provenance | store hidden model reasoning as evidence |

## 7. State, memory and evidence

| Data | Meaning | Authority |
|---|---|---|
| Session state | current workflow/research state | ADK |
| Long-term memory | reusable research context | ADK, advisory |
| Artifacts | versioned research outputs | ADK + evidence controls |
| Execution journal | crash/recovery envelope | Cusimanse |
| Evidence | observed, hashed, provenance-linked material | Cusimanse |
| Verified finding | conclusion supported by preserved evidence | verification stage |

A useful rule is: **memory helps the agent remember; evidence lets the system prove.**

## 8. What happens when the research needs more work?

The target workflow is an adaptive bounded loop:

```text
INTAKE
  ↓
REQUIREMENTS
  ↓
PLAN
  ↓
CAPABILITY REQUEST
  ↓
POLICY / APPROVAL
  ↓
EXECUTE
  ↓
OBSERVE
  ↓
ANALYZE
  ↓
VERIFY
  ↓
Acceptance criteria met?
  ├── YES → PRESERVE → REPORT → CLEANUP
  └── NO  → identify evidence gap
              ↓
           refine plan
              ↓
           next bounded iteration
```

A failed or ambiguous operation must not automatically be replayed if it may have caused a side effect. Recovery revalidates the operation first.

## 9. Security rules for testing

- Never give the model a raw shell or unrestricted host command interface.
- Never use production credentials or production targets for experiments.
- Unknown capabilities are denied.
- Policy denial cannot be overridden by model text or a research prompt.
- `Check()` happens before `Execute()`.
- Approval is explicit when required.
- Evidence is preserved separately from model reasoning.
- Disposable compute is destroyed only after required evidence is preserved.
- Recovery must be conservative and idempotent where possible.

## 10. Development and sanity checks

Run the smallest useful checks first:

```bash
go test ./...
go vet ./...
```

Then run the repository validation when the required host tools are installed:

```bash
bash ./scripts/tests/validate.sh
bash ./scripts/tests/integration.sh
```

For a clean local sanity check after dependency changes:

```bash
go mod tidy
go test ./...
go vet ./...
```

## 11. Repository structure

The branch intentionally keeps the runtime small and separates authority from orchestration:

```text
cmd/cusimanse-agent/       # interactive terminal agent
internal/agentadk/         # ADK Go 2 agent/workflow integration
internal/capability/       # executable capability contracts + registry
internal/policy/           # authorization and policy decisions
internal/state/            # durable recovery journal
internal/evidence/         # evidence/provenance authority
recipes/                   # declarative research/workload contracts
scripts/tests/             # repeatable validation
scripts/install.sh         # host setup

docs/ADK-GO-2-ARCHITECTURE.md
docs/ADK-GO-2-MIGRATION.md
```

Legacy Goose-specific runtime scaffolding is not part of this branch.

## 12. Current limitations

This is an active migration/test branch. The architecture is designed for an adaptive ADK Go 2 research loop, durable sessions, persistent memory/artifacts, provider-neutral model routing and stronger replay/idempotency controls. Those areas are being hardened incrementally.

## Documentation

- [`docs/ADK-GO-2-ARCHITECTURE.md`](docs/ADK-GO-2-ARCHITECTURE.md) — architecture and researcher workflow.
- [`docs/ADK-GO-2-MIGRATION.md`](docs/ADK-GO-2-MIGRATION.md) — implementation stages and security gates.
- [`docs/INSTRUMENTATION.md`](docs/INSTRUMENTATION.md) — guest instrumentation.
- [`docs/HOST-TOOLCHAIN.md`](docs/HOST-TOOLCHAIN.md) — host prerequisites.

## Design principles

1. Native Go agent runtime.
2. ADK Go 2 for agent orchestration.
3. Cusimanse for security authority.
4. Evidence over model reasoning.
5. Durable state and conservative recovery.
6. Disposable execution for untrusted workloads.
7. Provider-neutral security contracts.
8. Fail-closed authorization.
9. Framework-neutral capability core.
10. One coherent security research agent.

**Scope:** only `Opposum0112/Cusimanse` on `adk-cusimanse` is being changed for this evolution.