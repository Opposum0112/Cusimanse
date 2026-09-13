# 🦝 Cusimanse

> **Declarative, fully multiagentic security-research platform for controlled experiments, observable execution, evidence preservation and independent verification.**

Cusimanse turns Markdown research contracts and composable YAML recipes into repeatable, agent-operated research sessions. The selected primary agent owns the lifecycle; Lima/QEMU plus VM/OS controls provide the actual workload isolation boundary.

**Status:** beta research platform. Static validation is not proof of runtime isolation or production security.

## System requirements

| Area | Requirement |
|---|---|
| Host OS | Linux or macOS; Windows through WSL2 |
| CPU | Hardware virtualization recommended; 4+ cores recommended |
| RAM | 8 GB minimum; 16 GB+ recommended |
| Disk | 20 GB minimum; 40–50 GB+ recommended for VM images/evidence |
| Runtime | Lima + QEMU |
| Languages | Go, Python 3, Ruby |
| Utilities | Git, Bash, curl |
| Agent | At least one supported primary terminal agent |
| Network | Outbound access only where installation/experiment policy permits |

Detailed requirements, host package-manager support and preflight behavior are in [`docs/system-requirements.md`](docs/system-requirements.md).

## Architecture

![Cusimanse architecture](https://raw.githubusercontent.com/Opposum0112/Cusimanse/architecture-refactor/docs/architecture/cusimanse-architecture.svg)

**Canonical architecture source:** [`docs/architecture/cusimanse-architecture.svg`](docs/architecture/cusimanse-architecture.svg)

**Editable Mermaid workflow/source:** [`docs/architecture/cusimanse-architecture.mmd`](docs/architecture/cusimanse-architecture.mmd)

The architecture diagram shows the complete control/data-plane relationship: researcher intent → contract → recipe → session → normal host shell → policy → primary agent → specialist multiagent orchestration → disposable VM → instrumentation/workload → evidence/blackboard → verification/report → optional learning → dashboard/session finalization.

## Repository structure

```text
Cusimanse/
├── contracts/          # research contracts and reference semantics
├── recipes/            # executable declarative composition and profiles
├── experiments/        # reference experiment material/output
├── .agents/            # agent roles, skills and MCP metadata
├── skills/              # reviewed/promoted skills
├── packages/            # research packages
├── policies/            # host/action policy
├── infra/               # optional gateways/observability components
├── blackboard/          # durable case metadata
├── reports/             # generated reports/token history
├── docs/                # architecture + focused supporting guides
├── scripts/             # bootstrap/preflight/validation helpers
├── cmd/                 # policyctl and host tooling
└── tools/               # research-tool documentation
```

**Organization rule:** contracts describe research semantics; recipes describe execution composition; README explains the researcher workflow; `docs/` contains only focused supporting guides and canonical architecture. Avoid duplicate end-to-end workflow documents.

## Researcher workflow

The following is the canonical sequence. The command location is part of the workflow.

### Step 1 — Create an experiment from a contract + recipe

**Run from the normal host shell at the Cusimanse repository root.**

Use the existing Go experiment as the reference pattern:

```text
contracts/08-go-install-001.md
        │ defines purpose, safety, evidence and acceptance
        ▼
recipes/experiments/go-install-001.yaml
        │ composes profiles
        ├── recipes/workloads/go-install-001.yaml
        ├── recipes/host/research-host.yaml
        ├── recipes/lima/profiles/security-research.yaml
        ├── recipes/tools/security-research.yaml
        ├── recipes/agents/*
        ├── recipes/orchestration/*
        ├── recipes/audit/default.yaml
        ├── recipes/reporting/default.yaml
        └── recipes/observability/token-dashboard.yaml
```

For a new experiment:

1. Write `contracts/<id>.md` — what is being researched, scope, safety, evidence and acceptance.
2. Write `recipes/experiments/<id>.yaml` — how the workload and profiles are composed.
3. Write `recipes/workloads/<id>.yaml` — exact commands, execution location and evidence requirements.
4. Select the host, compute, tool, instrumentation, adapter, roles, skills/MCP, orchestration, policy, routing, audit, reporting and observability recipes.
5. Create `runs/<session-id>/session.yaml` from `recipes/session/session-state.yaml` and snapshot all selected profiles.
6. Validate the recipe graph before execution.

**Go reference:** `go-install-001` is the model to copy. **npm test:** use the already-provided `npm-install-001` experiment as the second reference workload.

### Step 2 — Prepare the host with the normal shell

From the repository root:

```bash
./scripts/cusimanse-host.sh
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
./scripts/tests/validate-project.sh
```

The host profile declares host tooling through `recipes/host/research-host.yaml` → `recipes/tools/security-research.yaml`. These commands install/prepare/validate the host. They do **not** execute the target workload.

### Step 3 — Select exactly one primary agent

Still in the **normal host shell**:

```bash
# Example
command -v goose && goose --help
```

Select one adapter from `recipes/agents/adapter-matrix.yaml`. Other examples are `opencode`, `grok`, `agy`, `pi`, `hermes`, `prime-agent`, `codex` and `claude`.

Record the selected adapter/version and prompt reference in `runs/<session-id>/session.yaml`.

### Step 4 — Start the primary agent

Starting the agent is a **normal host-shell action**. The lifecycle moves into the agent after startup.

Example:

```bash
goose
```

Provider-specific headless forms must be checked with the installed adapter's `--help`; do not assume every adapter accepts the same prompt flag.

### Step 5 — Give the experiment prompt to the primary agent

The prompt is entered **inside the primary agent**, not as normal host-shell commands.

For Go, use `docs/prompts/go-install-001.md`. For npm, use `docs/prompts/npm-install-001.md`.

The prompt tells the primary agent to load the contract, experiment recipe, session state and selected profiles, then perform:

```text
validate → preflight → plan → review/approval
→ provision VM → instrument → execute
→ collect/hash evidence → specialist analysis
→ independent verification → report
→ preserve → dashboard/token finalization → destroy VM
→ finalize session state
```

The researcher does **not** manually type these lifecycle commands one by one.

### Step 6 — Primary-agent multiagentic operation

The selected primary agent is the lifecycle authority. It coordinates the declared specialists:

```text
Primary agent
├── Planner
├── Researcher
├── Runtime analyst
├── Forensics analyst
├── Detection analyst
├── Analysis agent
├── Independent verifier
└── Report generator
```

Optional orchestration tools are used only when selected by recipe:

- **Taskflow:** breaks the research/learning task into replayable steps.
- **LangGraph:** provides optional stateful graph/checkpoint execution.
- **CrewAI:** delegates specialist roles.

They run under the primary agent; none is the sandbox or an independent lifecycle controller.

### Step 7 — Execute inside disposable compute

The primary agent provisions the declared Lima/QEMU profile. VM/OS controls enforce mounts, credentials, privilege and network restrictions. Instrumentation starts inside the VM **before** the workload.

#### Go test

The Go workload recipe declares the commands and execution boundary. The actual workload runs inside the disposable VM; it is not run directly on the research host.

```bash
go version
go install github.com/Opposum0112/ai-security-lab/packages/labprobe@v0.1.0
```

#### npm test

Use `recipes/workloads/npm-install-001.yaml`. The actual npm commands execute inside the disposable VM:

```bash
node --version
npm --version
mkdir -p /tmp/npm-test
cd /tmp/npm-test && npm init -y
cd /tmp/npm-test && npm install lodash@4.17.21 --ignore-scripts
```

The npm workload uses controlled networking and pinned package selection. Do not run these experiment commands directly on the research host.

### Step 8 — Evidence, report and session state

Each run is keyed by:

```text
runs/<session-id>/
├── session.yaml
├── audit/
├── evidence/raw/ + index.yaml
├── telemetry/
├── provenance/
├── blackboard/
├── analysis/
├── verification/
├── research-report/
├── preservation/
├── observability/
└── learning/
```

Raw evidence is ground truth and is hashed/preserved before VM destruction. The report distinguishes observation from inference and references the preserved artifacts.

### Step 9 — Optional learning / skill improvement

Learning runs **after the research result and verification**, only when the primary agent identifies a reusable improvement.

```text
research result
   ↓
create candidate
   ↓
Taskflow: split into replayable tasks
   ↓
primary-agent execution
   ↓
evaluate against contract
   ↓
refine
   ↓
optional LangGraph checkpoints/replay
   ↓
independent verification
   ↓
human approval
   ↓
promote validated skill/recipe improvement
```

The learning tools are installed/prepared through the selected host/control-plane profile. If the candidate requires workload execution, replay occurs in disposable compute. Learning produces candidate, evaluation, replay, verification and promotion records under `runs/<session-id>/learning/`. Nothing is promoted automatically, and learning cannot change the base contract, security policy, privileges or VM boundary.

### Step 10 — Close every session

The primary agent must finalize:

1. evidence preservation and hashes;
2. audit and provenance;
3. independent verification;
4. research report;
5. token accounting;
6. dashboard snapshot and active-session clearing;
7. final `session.yaml` status (`COMPLETE`, `PARTIAL` or `FAILED`);
8. disposable compute destruction only after preservation requirements are satisfied.

## Policyctl commands

`policyctl` is a **host-side governance/control-plane tool**, outside the agent control plane. It is not the sandbox.

### Validate policy configuration

```bash
./policyctl validate
```

### Check an action and append an audit record

```bash
./policyctl check --action credentials --audit-file /tmp/cusimanse-policy-audit.jsonl
./policyctl check --action host-root --audit-file /tmp/cusimanse-policy-audit.jsonl
./policyctl check --action crew-orchestration --audit-file /tmp/cusimanse-policy-audit.jsonl
```

Use policy decisions before applicable privileged, destructive, credential or orchestration actions and retain the audit reference in session state.

### Token/dashboard command

```bash
./policyctl token-dashboard
```

Session token accounting is finalized at the end of every session. Historical metrics may remain; the active session view is cleared/finalized.

## Runtime validation commands

### Static/project integration validation

Run from the repository root:

```bash
./scripts/tests/production-validation.sh
```

This validates the architecture, recipes, Go code, policy configuration and project integration. It does not prove Lima/QEMU runtime execution.

### Runtime smoke validation

Run on a suitable Linux/macOS research host with Lima and QEMU available:

```bash
export CUSIMANSE_LIMA_PROFILE=recipes/lima/profiles/security-research.yaml
./scripts/tests/runtime-integration.sh
```

Then verify the generated run:

```bash
./scripts/verify-run.sh reports/runtime/<run-id>
```

A runtime `PASS` requires actual disposable-compute execution, evidence, verification and a passing run verifier. GitHub-hosted static CI alone cannot establish runtime PASS.

## Security boundary

1. Human authorization defines scope.
2. Contracts and recipes define the permitted experiment.
3. The selected primary agent operates the approved lifecycle.
4. `policyctl` provides governance/policy decisions; it is not the sandbox.
5. Lima/QEMU plus VM/OS controls enforce workload isolation.
6. Instrumentation precedes target execution.
7. Evidence is preserved and hashed before destruction.
8. Important findings require independent verification.

Agents, skills, MCP, Taskflow, LangGraph, CrewAI and model/harness gateways are coordination or capability layers, not containment boundaries.

## Documentation

- [`docs/architecture/cusimanse-architecture.svg`](docs/architecture/cusimanse-architecture.svg) — canonical architecture rendering
- [`docs/architecture/cusimanse-architecture.mmd`](docs/architecture/cusimanse-architecture.mmd) — canonical Mermaid architecture/workflow source
- [`contracts/`](contracts/) — canonical research contracts
- [`recipes/`](recipes/) — declarative experiment/profile configuration
- [`docs/system-requirements.md`](docs/system-requirements.md) — detailed requirements
- [`docs/agent-shell-runbook.md`](docs/agent-shell-runbook.md) — adapter details
- [`docs/production-architecture.md`](docs/production-architecture.md) — deployment/security model
- [`docs/runtime-architecture.md`](docs/runtime-architecture.md) — runtime model
- [`docs/integration-status.md`](docs/integration-status.md) — integration status
- [`docs/prompts/`](docs/prompts/) — experiment-specific prompts

## Responsible use

Use Cusimanse only against systems and software you own or are explicitly authorized to test. Untrusted workloads belong in disposable compute. Human researchers remain responsible for authorization, scope, approvals, safety and final interpretation.

## License

MIT — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
