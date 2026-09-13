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
Selected primary agent adapter
      ↓
plan → review → approval
      ↓
disposable compute (Lima/QEMU + VM/OS controls)
      ↓
instrument → execute → collect
      ↓
blackboard + evidence + telemetry
      ↓
reduce → forensics → independent verification
      ↓
research report → preserve → destroy
```

Agents, prompts, skills, MCP, CrewAI and `policyctl` are coordination/governance layers, **not containment boundaries**. Enforcement depends on the compute/VM and host controls.

## Repository structure

```text
Cusimanse/
├── contracts/                 # research contracts and reference Markdown
│   ├── 01-deployment-architecture.md
│   ├── 02-system-requirements.md
│   ├── 03-deployment-runbook.md
│   ├── 04-security-model.md
│   ├── 05-multi-agent-operating-model.md
│   ├── 06-observability-and-evidence.md
│   ├── 07-experiment-framework.md
│   ├── 08-go-install-001.md
│   ├── 09-operations-and-maintenance.md
│   ├── 10-validation-and-acceptance.md
│   ├── 11-harness-reference.md
│   └── blackboard-schema.md
├── recipes/                  # declarative composition and registries
├── experiments/              # runnable reference experiments and outputs
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

## Quick start

### 1. Host preparation

```bash
./scripts/cusimanse-host.sh
```

The front door prepares the supported host and policy tooling. It does not silently start a research workload.

### 2. Validate the repository

```bash
./scripts/tests/production-validation.sh
```

### 3. Select and preflight an agent adapter

```bash
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
```

The selected primary agent shell is the runtime operator. You do **not** manually type every lifecycle stage as separate shell commands; the agent follows the declared contract after it is started and given the research task, subject to human approval gates.

### 4. Reference experiment

The reference experiment is `go-install-001`:

```bash
goose run --recipe recipes/goose/project.yaml \
  --params experiment=go-install-001 \
  --params section=project
```

The same semantic contract can be mapped to other adapters through `recipes/adapters/` and `recipes/agents/adapter-matrix.yaml`. Adapter availability must be evidenced; documented candidates are not automatically runtime-ready.

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
| Audit/reporting | `recipes/audit/`, `recipes/reporting/` |
| Validation | `recipes/tests/`, `scripts/tests/` |

Keep technical schema names such as `vm_profile` where they are part of an established recipe interface. In human-facing documentation, use **compute** when referring to the broader execution resource rather than the specific Lima/QEMU VM boundary.

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

CrewAI is an optional role-orchestration layer. It does not replace the primary adapter or the compute/VM security boundary.

## Skills, MCP and learning

Skills are declarative and versioned. MCP is a scoped capability/plugin layer. Neither grants privilege.

A candidate learned skill follows:

```text
retrieve → execute → evaluate → refine → replay
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

- [`contracts/`](contracts/) — canonical research contracts and reference Markdown
- [`docs/architecture/`](docs/architecture/) — canonical architecture source and rendered diagram
- [`docs/agent-shell-runbook.md`](docs/agent-shell-runbook.md) — adapter/operator runbook
- [`docs/production-architecture.md`](docs/production-architecture.md) — production architecture model
- [`docs/runtime-architecture.md`](docs/runtime-architecture.md) — runtime architecture
- [`docs/system-requirements.md`](docs/system-requirements.md) — system requirements overview
- [`docs/integration-status.md`](docs/integration-status.md) — integration status
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
