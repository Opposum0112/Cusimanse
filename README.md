# 🦝 Cusimanse

> A composable research-contract and YAML-recipe framework for agent-operated security experiments on disposable compute.

Cusimanse turns Markdown research contracts and declarative YAML recipes into repeatable research sessions. Contracts define purpose, scope, safety, evidence and acceptance. Recipes compose host, VM, workload, tools, instrumentation, agent, observability, routing, reporting and learning. The selected primary terminal agent owns the lifecycle and may use its native multi-agent/subagent capabilities. Lima/QEMU plus VM/OS controls enforce the workload boundary.

**Status:** beta research lab. This is not a certified sandbox, production security product or malware-detonation platform. Static validation is not proof of runtime isolation.

![Cusimanse mascot](docs/images/cusimanse-mascot.svg)

## AI use and usage disclaimer

Cusimanse is an **AI-assisted security research framework**. AI agents/models may plan experiments, delegate specialist work, operate declared workflows, interpret telemetry/evidence, generate reports and propose reusable skills. AI output may be incomplete, incorrect, nondeterministic or unsafe.

AI is a capability layer, **not a security boundary or authority to expand scope**. Humans remain responsible for authorization, scope, approvals, credentials, safety decisions and final interpretation. Do not put secrets, credentials or sensitive research data into prompts or telemetry unless explicitly authorized and protected. Review generated commands/findings before execution or publication and use disposable compute for untrusted workloads.

## System requirements

| Area | Requirement |
|---|---|
| Host | Linux/macOS; Windows through WSL2 |
| CPU | 4+ cores recommended; hardware virtualization recommended |
| RAM | 8 GB minimum; 16 GB+ recommended |
| Disk | 20 GB minimum; 40–50 GB+ recommended for VM images/evidence |
| Runtime | Lima + QEMU |
| Languages | Go, Python 3, Ruby |
| Utilities | Git, Bash, curl |
| Agent | At least one supported primary terminal agent |
| Network | Only where installation/experiment policy permits |

See [`docs/system-requirements.md`](docs/system-requirements.md) for detailed requirements.

## Architecture

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

- [`docs/architecture/cusimanse-architecture.svg`](docs/architecture/cusimanse-architecture.svg) — canonical rendering
- [`docs/architecture/cusimanse-architecture.mmd`](docs/architecture/cusimanse-architecture.mmd) — editable Mermaid source

**Configuration rule:** `recipes/` is the single configuration source of truth. There is no parallel `infra/` configuration tree.

## Repository structure

```text
contracts/       research contracts and acceptance semantics
recipes/         declarative execution composition and profiles
experiments/     reference experiment material
.agents/         agent roles, skills and MCP metadata
skills/          candidate/validated/promoted skill libraries
packages/        research packages
policies/        host/action policy
blackboard/      durable case metadata
reports/         generated reports and token history
manifest/        source-of-truth manifest
docs/            architecture and focused guides
scripts/         small installation/preflight/validation surface
cmd/             policyctl and host tooling
tools/           research-tool documentation
```

## Researcher workflow

### 1. Define an experiment

Create a Markdown contract and a YAML experiment recipe. Use `go-install-001` and `npm-install-001` as references.

```text
contract → experiment recipe → workload recipe → selected profiles
                                      ↓
                              primary agent session
                                      ↓
                         native specialist delegation
                                      ↓
                              disposable VM
                                      ↓
                         evidence → analysis → verification
                                      ↓
                              research report
                                      ↓
                         optional learning/promotion
```

The **recipe is the authoritative experiment input**. Experiment prompts in `docs/prompts/` are adapter-facing handoff artifacts for agents that benefit from a prompt-shaped invocation; they do not create a second configuration system.

### 2. Install the host

From the repository root:

```bash
./scripts/install.sh
./scripts/preflight.sh
./policyctl validate
./scripts/tests/validate.sh
```

`install.sh` is the single all-inclusive installation front door. It prepares prerequisites, policyctl, observability and optional model gateways. It does not start an agent, VM or gateway server.

The script directory intentionally has a small public surface. `prerequisites.sh`, `install-observability.sh` and `install-gateways.sh` are implementation helpers called by `install.sh`.

### 3. Select one primary agent

Choose exactly one adapter from `recipes/agents/adapter-matrix.yaml` and record it in the session state. Goose is the reference operator; other adapters remain targets until their provider-specific commands and runtime behavior are preflighted.

```bash
goose --help
goose
```

The selected agent becomes the lifecycle/operator authority. Do not introduce a competing lifecycle controller.

### 4. Operate the experiment

The primary agent reads the contract, experiment recipe, workload recipe and selected profiles, requests required approvals, provisions the declared Lima/QEMU environment, starts instrumentation, executes the workload, collects evidence, analyzes it, independently verifies findings, writes the report, preserves evidence and destroys disposable compute only after preservation.

The project declares specialist roles such as planner, researcher, runtime analyst, forensics analyst, detection analyst, analysis agent, verifier and report generator. The primary agent may delegate these roles through its **native** multi-agent/subagent capability.

### 5. Experiment prompts

Reference prompt adapters remain available:

- `docs/prompts/go-install-001.md`
- `docs/prompts/npm-install-001.md`

They are useful when a terminal agent needs a concise operational handoff. The recipe remains authoritative; the prompt is not a replacement for the recipe.

### 6. Agent observability

`recipes/agent-monitoring/observability.yaml` declares the agent-operation observability stack.

- **Numbat** — process, shell, network, filesystem and agent-tool activity.
- **Phoenix + OpenTelemetry** — traces, spans, model/tool calls, errors and approvals.
- **Aegis (`antropos17/Aegis`)** — independent OS-level observation of process, file, network and behavioral activity from outside the agent; it is monitor-first and not the isolation boundary.
- **Token dashboard** — per-session model/token accounting.

Install/check with:

```bash
./scripts/install.sh
./scripts/preflight.sh
cusimanse-token-dashboard
```

Missing optional observability backends are reported as `PARTIAL`/`NOT_DEPLOYED`; they are never silently treated as complete coverage.

## Optional learning and skill promotion

Learning is a **post-research, opt-in improvement loop**. It starts after the research report and independent verification when the primary agent identifies a reusable improvement.

`recipes/session/learning-workflow.yaml` is authoritative for the learning lifecycle. Learning helpers are installed on the **host/control plane only when selected**; they are not automatically installed in the workload VM.

Taskflow and LangGraph are optional learning helpers. The normal project architecture does **not** require CrewAI or another competing multi-agent framework because the selected primary agent owns orchestration.

```text
research report + verification
        ↓
identify improvement
        ↓
retrieve prior evidence / validated skills
        ↓
optional Taskflow decomposition
        ↓
primary-agent execution
        ↓
evaluate → refine candidate
        ↓
optional LangGraph state/checkpoints
        ↓
replay
        ↓
independent verification
        ↓
HUMAN APPROVAL
        ↓
skills/validated/ + registry update
        ↓
rollback if regression/safety issue appears
```

Candidate artifacts live under `runs/<session-id>/learning/`. Candidate skills are staged under `skills/candidate/`; only evidence-backed, replayed, independently verified and human-approved skills are promoted to `skills/validated/`. Base contracts cannot be mutated by the learning loop. Automatic privilege grants and security-policy changes are prohibited.

## Evidence and session state

Each session records identity, selected profiles, approvals, append-only audit, evidence, provenance, analysis, verification, report, preservation, observability and token accounting under `runs/<session-id>/`.

Raw evidence is ground truth. Model output is not evidence. Evidence must be hashed and preserved before disposable compute is destroyed.

## Validation

Validation has three project states:

- **PASS** — required static/project checks pass.
- **PARTIAL** — required structure is valid but optional capabilities are unavailable or unverified.
- **FAIL** — a required contract, safety or validation check fails.

`NOT_DEPLOYED` describes a missing capability; it is not a fourth project state.

```bash
./scripts/tests/validate.sh
```

The runtime smoke test is separate:

```bash
./scripts/tests/runtime.sh
```

A runtime `PASS` requires actual disposable Lima/QEMU execution and evidence/verification. CI/static validation cannot establish runtime PASS.

## Policy and security boundary

`policyctl` is host-side governance and is outside the agent control plane. It is **not** the sandbox.

```bash
./policyctl validate
./policyctl check --action credentials --audit-file /tmp/cusimanse-policy-audit.jsonl
./policyctl check --action host-root --audit-file /tmp/cusimanse-policy-audit.jsonl
./policyctl check --action vm --audit-file /tmp/cusimanse-policy-audit.jsonl
```

Security boundary order:

1. Human authorization and scope.
2. Contract and recipe constraints.
3. Primary-agent lifecycle operation.
4. Host-side policy decisions.
5. Lima/QEMU + VM/OS isolation.
6. Instrumentation before workload.
7. Evidence preservation and hashing.
8. Independent verification.

Agents, skills, MCP, learning helpers, observability and model gateways are capability/coordination layers, not containment boundaries.

## Documentation

- [`manifest/PACKAGE-MANIFEST.json`](manifest/PACKAGE-MANIFEST.json) — architecture/source-of-truth inventory
- [`contracts/`](contracts/) — canonical research contracts
- [`recipes/`](recipes/) — declarative source of truth
- [`docs/architecture/cusimanse-architecture.svg`](docs/architecture/cusimanse-architecture.svg) — canonical architecture
- [`docs/agent-shell-runbook.md`](docs/agent-shell-runbook.md) — adapter/run details
- [`docs/prompts/`](docs/prompts/) — experiment-specific agent handoffs
- [`scripts/README.md`](scripts/README.md) — script surface and responsibilities

## Responsible use

Use Cusimanse only against systems and software you own or are explicitly authorized to test. Untrusted workloads belong in disposable compute. Humans remain responsible for authorization, scope, approvals, safety and final interpretation.

## License

MIT — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
