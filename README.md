# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-operated security research on disposable compute.** Cusimanse lets a researcher declare intent and requirements while an agent selects registered capabilities and operates them through a policy-controlled Go capability API.

![Cusimanse agent-operated capability architecture](docs/architecture/cusimanse-architecture.svg)

> **Flow:** Contract → requirements → agent → capability registry → Go capability API → policy → disposable VM → instrumentation/workload → evidence → specialist analysis → independent verification → report → preservation → destroy.

## Table of contents

- [What Cusimanse is](#what-cusimanse-is)
- [Architecture](#architecture)
- [Researcher workflow](#researcher-workflow)
- [Host toolchain](#host-toolchain)
- [Gateway configuration](#gateway-configuration)
- [Observability and reports](#observability-and-reports)
- [Agent adapters and prompt handoff](#agent-adapters-and-prompt-handoff)
- [Quick start](#quick-start)
- [Go capability API](#go-capability-api)
- [Roles Skills and learning](#roles-skills-and-learning)
- [Profiles and requirements](#profiles-and-requirements)
- [Policy and safety](#policy-and-safety)
- [Evidence and reproducibility](#evidence-and-reproducibility)
- [Reference experiments](#reference-experiments)
- [Validation and integration tests](#validation-and-integration-tests)
- [Platform support](#platform-support)
- [Repository map](#repository-map)

## What Cusimanse is

Cusimanse is a **declarative research-contract, YAML-recipe and agent-operation framework**. The researcher describes **what is required**, not how to build infrastructure.

| Layer | Responsibility | Source of truth |
|---|---|---|
| Contract | Purpose, scope, authorization, acceptance | `contracts/` |
| Requirements | OS, isolation, workload, network, instrumentation | `recipes/experiments/` |
| Capability registry | Reusable host/workload capabilities | `recipes/profiles/registry.yaml` |
| Go capability API | Resolve, provision, configure, execute, collect, destroy | `cmd/cusimanse/` |
| Roles/Skills | Specialist behavior and least-scope delegation | `recipes/agents/role-skill-registry.json` |
| Policy | Allow, deny, approval and audit | `policies/host-policy.yaml` + Go runtime |
| Agent | Plan, select, operate, observe, adapt, analyze | Goose + specialist roles |
| Containment | Disposable execution boundary | Lima/QEMU guest |
| Evidence | Observations, provenance, verification and report | `runs/<session-id>/` |

The agent may operate registered capabilities, but cannot create trusted profiles, mutate infrastructure recipes, expand policy scope, or execute an untrusted research workload on the host.

## Architecture

1. **Declaration** — Markdown contract plus YAML requirements.
2. **Agent operation** — Goose is the reference operator; roles and Skills provide specialist behavior.
3. **Capability resolution** — Go matches requirements to versioned profiles and fails closed on no match or ambiguity.
4. **Policy control** — the Go capability runtime is the policy decision point; `scripts/policyctl` remains a compatibility/audit helper.
5. **Execution** — the provider operates Lima/QEMU and fixed workload handlers inside disposable compute.
6. **Research** — evidence is collected and hashed, then analyzed, independently verified, reported and preserved.

```text
Researcher says WHAT
       ↓
Experiment requirements
       ↓
Agent selects WHICH registered capability
       ↓
Go Capability API owns HOW
       ↓
Go policy decision + audit helper
       ↓
Lima/QEMU provides WHERE
       ↓
Evidence + observability
       ↓
Specialists → verifier → report-generator
       ↓
preserve → destroy
```

Model output is never trusted infrastructure or raw evidence.

## Researcher workflow

### 1. Write the contract

Define the research question, authorization, scope, acceptance criteria and safety constraints in `contracts/<experiment>.md`.

### 2. Declare requirements

```yaml
requirements:
  execution: disposable
  os: linux
  workload: npm
  network: localhost-only
  instrumentation: [process, syscall, filesystem, network]
```

Do not put VM commands, package installation, host mounts or model-generated infrastructure into experiment configuration.

### 3. Start Goose

```bash
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The recipe directs the agent to read the contract and requirements, resolve capabilities, obtain approval where required, and operate the Go API.

### 4. Resolve before execution

```bash
go run ./cmd/cusimanse resolve npm-threat-001
```

### 5. Approve and operate

```bash
go run ./cmd/cusimanse --approved run npm-threat-001
```

The lifecycle is `resolve → policy → provision → instrument → execute → collect → verify → report → preserve → destroy`.

### 6. Analyze, verify and report

The primary agent delegates runtime, forensics and detection analysis. The `verifier` independently checks evidence and conclusions. The `report-generator` creates the final researcher-facing report from the declared requirements, preserved evidence, specialist analysis, verification and observability metadata.

```text
observe → analyze → request declared capability → execute → observe
                         ↓
                 independent verifier
                         ↓
              report-generator role
                         ↓
                 report → preserve → destroy
```

## Host toolchain

The authoritative inventory is `recipes/host/security-research.yaml`. It separates common host commands, platform-specific host commands, guest-only instrumentation, mandatory gateways/observers and configuration locations. `scripts/install.sh` installs/configures the stack and `scripts/tools.sh` reports inventory, versions and configuration.

### Common host commands

| Command | Purpose |
|---|---|
| `git` | source control and provenance |
| `bash` | lifecycle scripts |
| `curl` | controlled installation downloads |
| `python3` | Python tooling and telemetry |
| `node` / `npm` | Node workloads and adapters |
| `go` | capability runtime and Go workloads |
| `jq` / `yq` | JSON/YAML processing |
| `rg` | repository/search operations |
| `goose` | reference agent and recipe orchestration |

`go` is a required host capability and is installed by `scripts/install.sh` on Linux and macOS. Numbat is installed with `go install`, so the Go toolchain is available before Numbat installation.

### Platform-specific host commands

| Platform | Commands | Notes |
|---|---|---|
| Linux | `limactl`, `qemu-system-x86_64` | Full reference path |
| macOS | `limactl`, `qemu-system-aarch64` | Apple Silicon path; Linux collectors run in guest |
| Windows + WSL2 | `limactl`, `qemu-system-x86_64` | Full reference experiments use WSL2 |
| Native Windows | none | Agent/repository fallback; full VM experiments require WSL2 |

### Guest instrumentation commands

`strace`, `tcpdump`, `ss`, `ip`, `dig`, `getent`, `lsof`, `find`, `stat`, `sha256sum`, `inotifywait`, `file`, `ps` and `pgrep` are guest tools, not native macOS/Windows prerequisites.

### Installation and inspection

```bash
./scripts/install.sh
./scripts/preflight.sh
./scripts/tools.sh list
./scripts/tools.sh versions
./scripts/tools.sh config
./scripts/tools.sh path
./scripts/tools.sh check
./scripts/tools.sh observability
./scripts/observability.sh status
```

The installer is idempotent, installs Go explicitly, configures the gateways/observability stack, and fails before experiments when required host capabilities are unavailable. Remote installers are downloaded to temporary files and syntax-checked before execution.

## Gateway configuration

`recipes/gateway/mandatory.yaml` defines localhost-only OmniRoute and LiteLLM endpoints:

```text
Agent / Goose
     ↓
LiteLLM :4000
     ↓
OmniRoute :20128
     ↓
configured model provider(s)
```

Configuration is generated under `~/.config/cusimanse/`; secrets remain in environment variables and are never written to Git-tracked recipes.

## Observability and reports

Cusimanse separates **agent observability** from **experiment evidence**:

> **Goose observes the agent; Cusimanse observes the experiment.**

| Tool | Purpose | Access |
|---|---|---|
| Numbat | monitoring records | `~/.numbat/cusimanse.ndjson`, `./scripts/tools.sh numbat` |
| Phoenix | LLM/agent traces | `http://127.0.0.1:6006` |
| OpenTelemetry | telemetry transport | `http://127.0.0.1:4318` |
| ClawMetry | Goose session/token visibility | `http://127.0.0.1:8900` |
| Aegis | independent observer | `~/.local/share/cusimanse/aegis/` |

For each run, preserve token/cost-oriented telemetry in `runs/<session-id>/observability/token-usage.yaml` when available. Never store API keys in telemetry artifacts.

Convenience commands:

```bash
./scripts/tools.sh numbat
./scripts/observability.sh numbat
./scripts/observability.sh phoenix
./scripts/observability.sh clawmetry
./scripts/observability.sh report <session-id>
```

See [`docs/OBSERVABILITY.md`](docs/OBSERVABILITY.md) for the detailed access model, correlation fields and reporting workflow.

### Report generation

`report-generator` is a first-class role and `report-generation` is a first-class Skill. It has no execution or policy mutation authority. It consumes:

- research requirements and contract
- preserved evidence and provenance
- runtime/forensics/detection analysis
- independent verification
- relevant observability/token metadata

and produces:

```text
runs/<session-id>/research-report/report.md
runs/<session-id>/research-report/report.yaml
```

The report must trace conclusions to evidence, distinguish observation from inference, state confidence and limitations, record partial/failed steps and describe reproducibility.

## Agent adapters and prompt handoff

Goose is the **native reference operator**. Other agents are adapters over the same contract, experiment configuration and prompt reference. Adapter prompts cannot mutate recipes or experiment scope.

| Agent | Command | Mode | Status |
|---|---|---|---|
| Goose | `goose` | native recipe | Reference |
| OpenCode | `opencode` | prompt handoff | NOT_DEPLOYED until runtime evidence |
| Hermes | `hermes` | prompt handoff | NOT_DEPLOYED until runtime evidence |
| Antigravity | `agy` | prompt handoff | NOT_DEPLOYED until runtime evidence |
| Pi | `pi` | prompt handoff | NOT_DEPLOYED until runtime evidence |

Every prompt follows: read contract → validate scope → resolve → approval → operate → observe → analyze → verify → report → preserve/destroy.

## Quick start

```bash
./scripts/install.sh
./scripts/preflight.sh
./scripts/tools.sh check
./scripts/tests/validate.sh
./scripts/tests/runtime.sh
./scripts/tests/integration.sh
```

Run a reference experiment:

```bash
go run ./cmd/cusimanse resolve npm-threat-001
go run ./cmd/cusimanse --approved run npm-threat-001
```

Compatibility wrapper:

```bash
./scripts/run-experiment.sh npm-threat-001
```

## Go capability API

The Go runtime is the agent-facing execution boundary:

```text
resolve
provision
configure
execute
collect
destroy
run
capability skill list
capability role list
capability skill upsert
capability role upsert
```

Examples:

```bash
go run ./cmd/cusimanse capability list
go run ./cmd/cusimanse capability skill list
go run ./cmd/cusimanse capability role list
go run ./cmd/cusimanse capability skill upsert --name runtime-analysis --description 'Analyze runtime behavior' --capabilities collect --tools jq,yq
go run ./cmd/cusimanse capability role upsert --name runtime-analyst --description 'Analyze runtime behavior' --skills runtime-analysis --capabilities execute,collect
```

Role/Skill upserts update the source-of-truth registry and regenerate the corresponding YAML consumers deterministically. They do **not** grant infrastructure authority or change policy.

## Roles Skills and learning

The managed source of truth is `recipes/agents/role-skill-registry.json`; generated role/Skill YAML lives under `.agents/agents/` and `recipes/skills/`. The generated binding contract is `recipes/agents/role-skill-bindings.yaml`.

| Role | Focus | Skills |
|---|---|---|
| Planner | scope and lifecycle planning | `experiment-run` |
| Researcher | execution and evidence interpretation | `experiment-run`, `evidence-analysis` |
| Runtime analyst | runtime/process/syscall/network behavior | `experiment-run`, `evidence-analysis` |
| Forensics analyst | filesystem/process/timeline analysis | `forensics`, `evidence-analysis` |
| Detection analyst | indicators and findings | `evidence-analysis` |
| Verifier | integrity and reproducibility | `verification`, `evidence-analysis` |
| Report generator | requirements-traceable reporting | `report-generation`, `evidence-analysis`, `verification` |

### Learning loop

Learning is **disabled by default**. It is a controlled experience-to-Skill loop:

```text
verified experience
      ↓
retrieve existing validated skills
      ↓
propose candidate skill + preconditions
      ↓
authorized disposable replay
      ↓
evaluate + independently verify
      ↓
human approval
      ↓
skills/validated/
```

Commands:

```bash
./scripts/learningctl status <session-id>
./scripts/learningctl candidate <session-id> <candidate-id> <file>
./scripts/learningctl promote <session-id> <candidate-id> --approved
```

Promotion requires preserved evidence, replay and independent verification. Learned Skills cannot mutate contracts, trusted profiles, policy scope or the execution boundary.

## Profiles and requirements

```text
recipes/profiles/
├── registry.yaml
├── host/linux-lima.yaml
└── workload/
    ├── go-install.yaml
    ├── npm-install.yaml
    ├── npm-lifecycle.yaml
    └── npm-threat.yaml
```

The registry is deterministic, permits agent selection and forbids agent-created profiles. Resolution fails closed on no match or ambiguity. Host profiles forbid model-generated provisioning/instrumentation; workload profiles use fixed handlers and cannot be modified by the agent.

## Policy and safety

The **Go capability runtime is the intended policy decision point**. The policy definition remains declarative in `policies/host-policy.yaml`.

`scripts/policyctl` is retained as a compatibility/audit helper for shell users, CI and existing recipes. It is **not an independent security authority** and should not be treated as a second policy engine.

```bash
./scripts/policyctl validate
./scripts/policyctl check vm
./scripts/policyctl check network
./scripts/policyctl check credentials
./scripts/policyctl check mounts
./scripts/policyctl audit
```

The security boundary remains:

```text
authorization + policy
        ↓
Go capability API
        ↓
Lima/QEMU disposable VM
        ↓
workload + declared instrumentation
```

Gateways, MCP, Skills, model adapters and observability improve agent operation and visibility but cannot replace containment.

## Evidence and reproducibility

```text
runs/<session-id>/
├── session.yaml
├── evidence/
│   ├── audit/events.jsonl
│   └── index.yaml
├── provenance/manifest.sha256
├── analysis/summary.md
├── verification/result.md
├── research-report/report.md
├── research-report/report.yaml
├── observability/token-usage.yaml
├── observability/dashboard.yaml
├── learning/
└── preservation/manifest.yaml
```

Evidence is hashed and provenance preserved before destruction. Model output is analysis, not raw evidence. Final conclusions require independent verification.

## Reference experiments

| Experiment | Requirements | Purpose |
|---|---|---|
| `go-install-001` | disposable Linux Go | Go install/build baseline |
| `npm-install-001` | disposable Linux npm | pinned npm install with lifecycle disabled |
| `npm-lifecycle-001` | disposable Linux npm + localhost-only | controlled local postinstall |
| `npm-threat-001` | disposable Linux npm + localhost-only | adversarial-like controlled lifecycle fixture |

The npm threat fixture is local and harmless, not real malware, and does not receive credentials or external network authorization.

## Validation and integration tests

### Static validation

```bash
./scripts/tests/validate.sh
```

Validates Go, recipes, manifests, role/Skill generated consumers, report generation, learning rules, observability configuration, policy, architecture assets and executable shell scripts.

### Runtime/control-plane validation

```bash
./scripts/tests/runtime.sh
```

Runs Go tests, policy checks, lifecycle/evidence checks and capability resolution. Optional VM smoke test:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

### Integration validation

```bash
./scripts/tests/integration.sh
```

The integration test covers host inventory → gateways/observability → adapters/prompts → Goose recipes → role/Skill management → capability resolution → policy → session lifecycle → evidence hashing. VM mode validates the Lima recipe, checks guest Go/Node/npm/instrumentation and destroys the disposable VM.

CI does not claim a disposable-VM pass unless VM mode actually runs.

## Platform support

| Platform | Support |
|---|---|
| Linux | Full reference path |
| macOS | Lima/QEMU Linux guest |
| Windows 10/11 + WSL2 | Supported Linux path |
| Native Windows | Limited agent-only fallback; full experiments require WSL2 |

## Repository map

```text
Cusimanse/
├── .agents/                    # agent roles and Skills
├── cmd/cusimanse/              # Go capability API/runtime
├── contracts/                  # research contracts
├── prompts/experiments/        # agent-neutral prompt handoffs
├── policies/                   # declarative policy
├── recipes/
│   ├── experiments/            # researcher requirements
│   ├── profiles/               # capability registry + profiles
│   ├── agents/                 # Goose orchestration + role/Skill registry
│   ├── gateway/                # mandatory model gateway
│   ├── observability/          # mandatory host observability
│   ├── host/                   # host tool inventory
│   ├── session/                # lifecycle + learning contract
│   ├── subrecipes/             # delegated research tasks
│   ├── lima/                   # disposable VM recipe
│   └── instrumentation/        # guest telemetry recipe
├── scripts/                    # installer, helpers, lifecycle, learning and tests
├── docs/architecture/          # Mermaid source + rendered architecture
├── docs/OBSERVABILITY.md       # observability/report access guide
├── manifest/                   # package/source-of-truth manifest
├── packages/                   # controlled workload fixtures
└── runs/                       # generated research sessions
```

## Design principle

> **Researchers declare intent and requirements. Agents select and operate capabilities. The Go API provides the capability boundary. Policy controls authority. Profiles define reusable infrastructure. Lima/QEMU contains execution. Evidence is preserved and independently verified.**
