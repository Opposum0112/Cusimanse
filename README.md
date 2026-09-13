# 🦝 Cusimanse

<p align="center">
  <img src="docs/images/cusimanse-mascot.svg" alt="Cusimanse mascot" width="1000">
</p>

> **Declarative, fully multiagentic security-research platform for controlled experiments, observable execution, evidence preservation and independent verification.**

Cusimanse turns a Markdown research contract plus composable YAML recipes into a repeatable agent-operated research run. The selected primary agent coordinates the lifecycle; Lima/QEMU and VM/OS controls provide the actual workload isolation boundary.

**Status:** beta research platform. A green static check is not proof of runtime isolation or production security.

## Architecture

![Cusimanse architecture](docs/images/cusimanse-architecture.png)

The canonical vector architecture is [`docs/architecture/cusimanse-architecture.svg`](docs/architecture/cusimanse-architecture.svg), with Mermaid source in [`docs/architecture/cusimanse-architecture.mmd`](docs/architecture/cusimanse-architecture.mmd).

### Operating model

```text
Research intent
      ↓
Markdown contract + YAML recipe graph
      ↓
Research session YAML + selected profiles
      ↓
Selected primary agent adapter
      ↓
plan → review → approval
      ↓
disposable compute (Lima/QEMU + VM/OS controls)
      ↓
instrument → execute → collect
      ↓
blackboard + evidence + telemetry + audit
      ↓
reduce → forensics → independent verification
      ↓
research report → preserve → dashboard finalize → destroy
```

Agents, prompts, skills, MCP, CrewAI, LangGraph, Taskflow and `policyctl` are coordination/governance layers, **not containment boundaries**. Enforcement depends on the compute/VM and host controls.

## Repository structure

```text
Cusimanse/
├── contracts/                 # research contracts and reference Markdown
├── recipes/                  # declarative composition, profiles and registries
│   └── session/               # session-state and learning workflow contracts
├── experiments/               # runnable reference experiments and outputs
├── .agents/                  # agent roles, skills and MCP client metadata
├── skills/                   # reviewed/promoted project skills
├── packages/                 # small research packages such as labprobe
├── policies/                 # host and action policy definitions
├── infra/                    # optional gateways, observability and tooling
├── blackboard/               # durable case coordination metadata
├── reports/                  # generated research output
├── docs/                     # focused supporting documentation and diagrams
├── scripts/                  # host bootstrap, validation and helper utilities
├── cmd/                      # `policyctl` and host tooling
└── tools/                    # research-tool documentation
```

`contracts/` is the canonical home for the reference Markdown. `recipes/` is the canonical home for executable configuration. `scripts/` does not become a second experiment controller.

## End-to-end research workflow

The complete researcher → host → primary-agent → evidence → learning workflow is specified in [`docs/research-workflow.md`](docs/research-workflow.md). The durable session contract is [`recipes/session/session-state.yaml`](recipes/session/session-state.yaml), and the evidence-bounded learning contract is [`recipes/session/learning-workflow.yaml`](recipes/session/learning-workflow.yaml).

### 1. Create the experiment

Create the Markdown contract under `contracts/`, then compose the YAML experiment recipe under `recipes/experiments/`. The recipe selects the workload, host profile, compute profile, tools, instrumentation, primary agent, specialist roles, skills, MCP, orchestration, policy, routing, reporting and observability. Start a new `runs/<session-id>/session.yaml` from the session contract and snapshot all selected profile references and input digests.

### 2. Prepare the host with the normal shell

```bash
./scripts/cusimanse-host.sh
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
./scripts/tests/validate-project.sh
```

The host profile declares the host tool recipe. Host scripts prepare and validate; they do not own the research lifecycle. Instrumentation for the target workload belongs inside disposable compute.

### 3. Select exactly one primary agent adapter

Use `recipes/agents/adapter-matrix.yaml` and record the selected adapter/version in session state. Native examples:

```bash
goose
opencode
opencode run '<PROMPT>'
grok -p '<PROMPT>'
agy -p '<PROMPT>'
pi -p '<PROMPT>'
hermes
prime-agent -p '<PROMPT>'
codex
claude '<PROMPT>'
```

Verify provider-specific CLI syntax with `<adapter> --help`. CLI availability is not runtime acceptance.

### 4. Start the agent and provide the experiment prompt

The primary agent is the operator. The researcher does **not** type every lifecycle stage as separate shell commands. Give the selected agent the shared experiment prompt from the canonical runbook/workflow, including the session ID, experiment ID and contract/profile references. The agent then performs discover → validate → preflight → plan → review → approval → provision → instrument → execute → collect → analysis → verification → report → preserve → dashboard finalization → destroy.

### 5. Store evidence and report by session

Each session has a durable artifact root at `runs/<session-id>/`, containing `session.yaml`, audit events/manifests, raw evidence and index, telemetry, provenance, blackboard records, analysis, independent verification, research report, preservation manifest, token usage and a dashboard snapshot. Raw evidence is hashed and preserved before compute destruction.

### 6. Finalize every session

At session end, finalize audit/provenance, token accounting and the dashboard snapshot; mark the session `COMPLETE`, `PARTIAL` or `FAILED`; then destroy disposable compute only after preservation requirements are satisfied. Historical aggregate metrics may remain, but the active session dashboard must not retain a prior run as active.

### 7. Evidence-bounded learning

Learning follows retrieve → taskflow decomposition → execute → evaluate → refine → replay → independent verification → human approval → promote → rollback when necessary. Taskflow, LangGraph and CrewAI may provide declared task decomposition/stateful execution/specialist delegation. They cannot bypass the primary agent, policy, approvals, evidence integrity or compute boundary. Learned skills cannot autonomously grant privilege or mutate base contracts.

## Contracts and recipes

A research contract defines **what must be true**: intent, scope, hypothesis, safety, evidence, acceptance and review requirements.

Recipes define **how the case is composed**:

| Concern | Location |
|---|---|
| Contracts / reference Markdown | `contracts/` |
| Experiments | `recipes/experiments/` |
| Workloads | `recipes/workloads/` |
| Compute / Lima profiles | `recipes/lima/profiles/` |
| Host profiles | `recipes/host/` |
| Instrumentation | `recipes/instrumentation/` |
| Agent adapters | `recipes/adapters/` |
| Primary agent + roles | `recipes/agents/` |
| Skills | `recipes/skills/` |
| MCP | `recipes/mcp/` |
| Specialist orchestration | `recipes/orchestration/` |
| Model/harness routing | `recipes/routing/` |
| Observability | `recipes/observability/` |
| Session state + learning | `recipes/session/` |
| Audit/reporting | `recipes/audit/`, `recipes/reporting/` |
| Validation | `recipes/tests/`, `scripts/tests/` |

## Fully multiagentic workflow

The platform separates specialist responsibilities while keeping one selected primary agent as operator authority:

- **Planner** — objective, hypothesis and success criteria
- **Researcher** — expected behavior, references and instrumentation
- **Runtime analyst** — execution telemetry and behavioral analysis
- **Forensics analyst** — evidence reduction and forensic findings
- **Detection analyst** — verified behavior to detections
- **Analysis agent** — correlation and interpretation
- **Verifier** — independent challenge and replay
- **Report generator** — reproducible research report

CrewAI is an optional role-orchestration layer. LangGraph and Taskflow are optional stateful/taskflow layers. None replaces the primary adapter or the compute/VM security boundary.

## Skills, MCP and learning

Skills are declarative and versioned. MCP is a scoped capability/plugin layer. Neither grants privilege.

A candidate learned skill follows:

```text
retrieve → taskflow → execute → evaluate → refine → replay
→ independent verification → human approval → validated skill
```

Base contracts remain immutable during learning. Security boundaries, credentials, privileges, network allowlists, approval requirements and evidence-integrity controls remain outside autonomous promotion authority.

## Evidence and research reports

The blackboard stores durable case metadata, audit events, evidence indexes, telemetry, findings, verification state and provenance. Raw evidence remains the ground truth.

A successful research run produces a human-reviewable **research report** backed by preserved evidence, hashes and independent verification. AI output is never accepted as evidence by itself.

## Security boundary

The security model is intentionally explicit:

1. Human authorization defines scope.
2. Contracts and recipes define the permitted experiment.
3. The primary agent operates only the approved lifecycle.
4. `policyctl` provides policy decisions and token accounting; it is not the sandbox.
5. Lima/QEMU plus VM/OS controls enforce disposable workload isolation.
6. Instrumentation starts before target execution.
7. Evidence is preserved and hashed before compute destruction.
8. Important findings require independent verification.

Never expose credentials, unrestricted host mounts or public MCP/gateway endpoints merely because an agent requests them.

## Token observability

Token accounting is available through the project dashboard:

```bash
./policyctl token-dashboard
```

The token ledger is maintained under `reports/token-usage/usage.json` when enabled. Routing gateways such as LiteLLM and OmniRoute are traffic-routing components, not security boundaries.

## Integration testing and runtime acceptance

### Static validation

```bash
./scripts/tests/production-validation.sh
```

### Important runtime boundary

**The actual Lima/QEMU runtime test cannot truthfully be marked PASS from GitHub's normal hosted CI. It must be executed on a suitable research host with Lima/QEMU available.**

Run:

```bash
./scripts/tests/production-validation.sh

export CUSIMANSE_LIMA_PROFILE=recipes/lima/profiles/security-research.yaml
./scripts/tests/runtime-integration.sh

./scripts/verify-run.sh reports/runtime/<run-id>
```

Runtime acceptance is `PASS` only when the runtime test actually completes successfully and the generated run passes `scripts/verify-run.sh`. Hosted CI static checks are useful, but they are not evidence of Lima/QEMU execution unless the runner genuinely provides and exercises that environment.

The runtime smoke test provisions disposable compute, executes a safe workload inside it, captures VM-side telemetry/evidence, creates a verifier-compatible run structure and removes the compute environment after evidence preservation. It is intentionally a smoke acceptance test, not proof of every adapter, instrumentation backend, gateway, observability integration or full production security posture.

## Acceptance states

| State | Meaning |
|---|---|
| `PASS` | behavior was actually exercised and supported by evidence |
| `PARTIAL` | capability worked but coverage or evidence is incomplete |
| `FAIL` | required contract or safety condition was not met |
| `NOT_DEPLOYED` | capability is unavailable or intentionally not exercised |

Configuration alone never establishes `PASS`.

## Documentation

- [`docs/research-workflow.md`](docs/research-workflow.md) — canonical end-to-end research session workflow
- [`contracts/`](contracts/) — canonical research contracts and reference Markdown
- [`docs/architecture/`](docs/architecture/) — canonical architecture source and rendered diagram
- [`docs/agent-shell-runbook.md`](docs/agent-shell-runbook.md) — adapter/operator runbook
- [`docs/production-architecture.md`](docs/production-architecture.md) — production architecture model
- [`docs/runtime-architecture.md`](docs/runtime-architecture.md) — runtime architecture
- [`docs/system-requirements.md`](docs/system-requirements.md) — system requirements overview
- [`docs/integration-status.md`](docs/integration-status.md) — integration status
- [`recipes/session/`](recipes/session/) — session state and learning contracts
- [`recipes/README.md`](recipes/README.md) — recipe architecture
- [`scripts/README.md`](scripts/README.md) — script boundaries
- [`SECURITY.md`](SECURITY.md) — security model and reporting
- [`AI-DISCLAIMER.md`](AI-DISCLAIMER.md) — AI limitations and responsible use
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — contribution workflow
- [`RELEASE.md`](RELEASE.md) — release process

## Responsible use

Use Cusimanse only against systems and software you own or are explicitly authorized to test. Untrusted workloads belong in disposable compute/VM environments. Human researchers remain responsible for authorization, scope, approvals, safety and final interpretation.

## License

MIT — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
