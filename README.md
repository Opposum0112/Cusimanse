# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-operated security research on disposable compute.** Cusimanse lets a researcher declare intent and requirements while an agent selects registered capabilities and operates them through a policy-controlled Go capability API.

![Cusimanse agent-operated capability architecture](docs/architecture/cusimanse-architecture.svg)

> **Flow:** Contract → requirements → agent → capability registry → Go capability API → policy gate → disposable VM → instrumentation/workload → evidence → specialist analysis → independent verification → report → preservation → destroy.

## Table of contents

- [What Cusimanse is](#what-cusimanse-is)
- [Architecture](#architecture)
- [Researcher workflow](#researcher-workflow)
- [Host toolchain](#host-toolchain)
- [Gateway configuration](#gateway-configuration)
- [Agent adapters and prompt handoff](#agent-adapters-and-prompt-handoff)
- [Quick start](#quick-start)
- [Go capability API](#go-capability-api)
- [Profiles and requirements](#profiles-and-requirements)
- [Policy and safety](#policy-and-safety)
- [Agent roles and Skills](#agent-roles-and-skills)
- [Evidence and reproducibility](#evidence-and-reproducibility)
- [Reference experiments](#reference-experiments)
- [Validation and integration tests](#validation-and-integration-tests)
- [Platform support](#platform-support)
- [Repository map](#repository-map)

## What Cusimanse is

Cusimanse is a **declarative research-contract, YAML-recipe and agent-operation framework**. The researcher describes **what is required**, not how to build the infrastructure.

| Layer | Responsibility | Source of truth |
|---|---|---|
| Contract | Purpose, scope, authorization, acceptance | `contracts/` |
| Requirements | OS, isolation, workload, network, instrumentation | `recipes/experiments/` |
| Capability registry | Reusable host/workload capabilities | `recipes/profiles/registry.yaml` |
| Go capability API | Resolve, provision, configure, execute, collect, destroy | `cmd/cusimanse/` |
| Policy | Allow, deny, approval and audit | `scripts/policyctl` + `policies/` |
| Agent | Plan, select, operate, observe, adapt, analyze | Goose + specialist roles |
| Containment | Disposable execution boundary | Lima/QEMU guest |
| Evidence | Raw observations, provenance, verification and report | `runs/<session-id>/` |

The agent may provision and execute, but only by operating registered capabilities. It cannot create trusted profiles, mutate infrastructure recipes, expand policy scope, or execute the research workload on the host.

## Architecture

1. **Declaration** — Markdown contract plus YAML requirements.
2. **Agent operation** — Goose is the reference operator; roles and Skills provide specialist behavior.
3. **Capability resolution** — Go matches requirements to versioned profiles and fails closed on no match or ambiguity.
4. **Policy control** — `policyctl` gates VM, network, mounts, credentials, host execution and other privileged actions.
5. **Execution** — the provider operates Lima/QEMU and fixed workload handlers inside disposable compute.
6. **Research** — evidence is collected and hashed, then analyzed, independently verified, reported and preserved.

```text
Researcher says WHAT
       ↓
Experiment requirements
       ↓
Agent decides WHICH registered capability
       ↓
Go Capability API decides HOW to operate it
       ↓
policyctl decides WHETHER the action is allowed
       ↓
Lima/QEMU provides WHERE execution is contained
       ↓
Evidence returns to the agent for analysis/adaptation
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

Do not put VM commands, package installation, host mounts or model-generated infrastructure into the experiment configuration.

### 3. Start Goose

```bash
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The recipe directs the agent to read the contract and requirements, resolve capabilities, obtain approval where required, and operate the Go API.

### 4. Resolve before execution

```bash
go run ./cmd/cusimanse resolve npm-threat-001
```

Expected profiles:

```text
host_profile: recipes/profiles/host/linux-lima.yaml
workload_profile: recipes/profiles/workload/npm-threat.yaml
```

### 5. Approve and operate

```bash
go run ./cmd/cusimanse --approved run npm-threat-001
```

The runtime performs `resolve → policy → provision → instrument → execute → collect → hash`.

### 6. Analyze and verify

The primary agent delegates specialist analysis, independently verifies evidence and conclusions, and then produces the research report.

```text
observe → analyze → request declared capability → execute → observe
                         ↓
                 independent verifier
                         ↓
                 report → preserve → destroy
```

### 7. Preserve before destroy

Evidence, provenance, analysis and verification are finalized before disposable compute is destroyed. If a required capability is unavailable, record `PARTIAL`; do not silently weaken the experiment.

## Host toolchain

The authoritative inventory is `recipes/host/security-research.yaml`. It separates common host commands, platform-specific host commands, guest-only instrumentation, mandatory gateways/observers and configuration locations. `scripts/install.sh` installs/configures the stack and `scripts/tools.sh` reports inventory, versions and configuration. fileciteturn195file0

### Common host commands

| Command | Purpose |
|---|---|
| `git` | source control and provenance |
| `bash` | lifecycle scripts |
| `curl` | controlled installation downloads |
| `python3` | Python tooling and telemetry |
| `node` | npm workloads and adapter installation |
| `npm` | Node package workloads |
| `go` | capability runtime and Go workloads |
| `jq` | JSON processing |
| `yq` | YAML/configuration processing |
| `rg` | repository/search operations |
| `goose` | reference agent and recipe orchestration |

### Platform-specific host commands

| Platform | Commands | Notes |
|---|---|---|
| Linux | `limactl`, `qemu-system-x86_64` | Full reference path |
| macOS | `limactl`, `qemu-system-aarch64` | Apple Silicon ARM QEMU; Linux collectors run in guest |
| Windows + WSL2 | `limactl`, `qemu-system-x86_64` | Full reference experiments use Linux/WSL2 |
| Native Windows | none | Agent/repository fallback; full VM experiments require WSL2 |

### Guest instrumentation commands

These are guest tools, not native macOS/Windows prerequisites:

```text
strace        syscall tracing
tcpdump       packet capture
ss            socket/network state
ip            interfaces/routes/network state
dig           DNS observation
getent        name/service lookup
lsof          open files/sockets/process relationships
find          filesystem enumeration
stat          file metadata/timestamps
sha256sum     evidence hashing
inotifywait   filesystem event observation
file          file-type identification
ps            process inventory
pgrep         process lookup
```

This host/guest split prevents Linux-only collectors being incorrectly treated as native host requirements. fileciteturn195file0

### Mandatory services and observability

The host contract declares Goose, OmniRoute and LiteLLM plus Numbat, Aegis, Phoenix, OpenTelemetry and ClawMetry as the mandatory agent/gateway/observability stack. Observers and gateways are not the workload security boundary. fileciteturn195file0turn198file0

| Component | Interface | Role |
|---|---|---|
| Goose | `goose` | primary agent/orchestrator |
| OmniRoute | `omniroute` | routing/provider fallback |
| LiteLLM | `litellm` | model gateway/normalization |
| Numbat | `numbat` | monitoring |
| Aegis | `~/.local/share/cusimanse/aegis/` | independent observer |
| Phoenix | Python `phoenix` | telemetry/tracing |
| OpenTelemetry | Python `opentelemetry` | telemetry/export |
| ClawMetry | `clawmetry` | Goose session/token visibility |

### Installation and inspection commands

```bash
./scripts/install.sh
./scripts/preflight.sh
./scripts/tools.sh list
./scripts/tools.sh versions
./scripts/tools.sh config
./scripts/tools.sh path
./scripts/tools.sh check
```

`tools.sh list` reports every declared command, Python package and Aegis checkout. `versions` prints command paths/versions; `config` prints configuration locations without secrets. fileciteturn194file0

The installer is idempotent and fails before an experiment if required capabilities are missing. Remote installer scripts are downloaded to a temporary file and syntax-checked before execution. Pinned components include Goose `1.50.0`, Numbat `0.2.0`, OmniRoute `3.8.50` and Pi `0.74.0`; Aegis is pinned to a repository commit. fileciteturn197file0turn201file0

## Gateway configuration

The mandatory gateway recipe is `recipes/gateway/mandatory.yaml`. OmniRoute binds to `127.0.0.1:20128`; LiteLLM binds to `127.0.0.1:4000` and routes to OmniRoute. Both are localhost-only and are **not** security boundaries. fileciteturn197file0

```text
Agent / Goose
     ↓
LiteLLM :4000
     ↓
OmniRoute :20128
     ↓
configured model provider(s)
```

The installer generates:

```text
~/.config/cusimanse/litellm.yaml
~/.config/cusimanse/omniroute.env
~/.config/cusimanse/goose.env
~/.config/cusimanse/observability.env
```

LiteLLM uses the OpenAI-compatible `openai/auto` route through OmniRoute. Gateway secrets are supplied through environment variables, not Git-tracked recipes. Goose points its OpenAI-compatible client at the local LiteLLM endpoint. Observability endpoints are configured separately. fileciteturn201file0

## Agent adapters and prompt handoff

Goose is the **native reference operator**. Other agents are adapters over the same contract, experiment configuration and prompt reference. Adapter prompts are handoffs; they cannot mutate recipes or experiment scope. fileciteturn205file0

| Agent | Command | Mode | Native capabilities | Status |
|---|---|---|---|---|
| Goose | `goose` | native recipe | recipes, subrecipes, summon, Skills, MCP/extensions, delegation | Reference |
| OpenCode | `opencode` | prompt handoff | agents, plugins, MCP | NOT_DEPLOYED until runtime evidence |
| Hermes | `hermes` | prompt handoff | tools, Skills, delegation | NOT_DEPLOYED until runtime evidence |
| Antigravity | `agy` | prompt handoff | agents, tools, delegation | NOT_DEPLOYED until runtime evidence |
| Pi | `pi` | prompt handoff | extensions, Skills, packages | NOT_DEPLOYED until runtime evidence |

Optional adapters are selected interactively or with `CUSIMANSE_INSTALL_ADAPTERS=opencode,hermes,antigravity,pi`. Installation is idempotent; failed optional adapters are `PARTIAL`, while Goose failure is `FAIL`. fileciteturn197file0

### Prompt steps

Every `prompts/experiments/<experiment>.md` is a controlled handoff. A compliant adapter follows this sequence:

1. **Read first:** contract, experiment YAML, session-state and instrumentation recipe.
2. **Validate scope:** authorization, workload, isolation, network and telemetry requirements.
3. **Resolve:** run `go run ./cmd/cusimanse resolve <experiment>` and use only returned registered capabilities.
4. **Obtain approval:** stop for researcher approval before approval-gated, privileged or destructive actions.
5. **Operate:** invoke the Go capability runtime; never invent VM commands or mutate trusted profiles.
6. **Observe:** start declared instrumentation before workload execution and preserve raw evidence.
7. **Analyze:** delegate runtime, forensics and detection analysis to the appropriate roles/Skills.
8. **Verify:** independently cross-check evidence, hashes and reproducibility.
9. **Report:** record findings, confidence and limitations.
10. **Preserve then destroy:** preserve artifacts/manifests before destroying disposable compute.

The adapter contract requires `session.yaml`, `evidence/`, `verification/` and `research-report/`. A CLI being installed is not sufficient to mark an adapter deployed; runtime evidence and independent verification are required. fileciteturn205file0

## Quick start

```bash
./scripts/install.sh
./scripts/preflight.sh
./scripts/tools.sh check
./scripts/policyctl validate
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
```

CLI surface:

```bash
go run ./cmd/cusimanse capability list
go run ./cmd/cusimanse resolve <experiment>
go run ./cmd/cusimanse --approved run <experiment> [session-id]
```

The API separates agent decisions from infrastructure implementation: resolver → registered profile → policy gate → provider/fixed handler → disposable compute. The initial provider is Lima/QEMU. `--approved` represents explicit researcher approval and never overrides a policy denial.

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

The registry is deterministic, permits agent selection and forbids agent-created profiles. Resolution fails closed on no match or ambiguity. The host profile forbids model-generated provisioning/instrumentation; workload profiles use fixed handlers and cannot be modified by the agent. fileciteturn201file0

## Policy and safety

`policyctl` is the single policy control surface:

```bash
./scripts/policyctl validate
./scripts/policyctl check vm
./scripts/policyctl check network
./scripts/policyctl check credentials
./scripts/policyctl check mounts
./scripts/policyctl require vm --approved
./scripts/policyctl audit
```

The security boundary is:

```text
policy + authorization
        ↓
Go capability API
        ↓
Lima/QEMU disposable VM
        ↓
workload + declared instrumentation
```

Gateways, MCP, Skills, model adapters and observability improve agent operation and visibility but cannot replace containment.

## Agent roles and Skills

| Role | Focus | Skills |
|---|---|---|
| Planner | scope, planning, lifecycle preparation | `experiment-run` |
| Researcher | execution and evidence interpretation | `experiment-run`, `evidence-analysis` |
| Runtime analyst | process/syscall/network/runtime behavior | `experiment-run`, `evidence-analysis` |
| Forensics analyst | filesystem/process artifacts and timelines | `forensics`, `evidence-analysis` |
| Detection analyst | indicators and security findings | `evidence-analysis` |
| Verifier | independent integrity and reproducibility | `verification`, `evidence-analysis` |
| Report generator | findings, confidence and limitations | `evidence-analysis`, `verification` |

Goose orchestration permits analysis specialists to work in parallel while keeping provision, workload, verification, reporting, preservation and destruction controlled in sequence. The adaptive loop is restricted to declared capabilities. fileciteturn198file0

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

Checks the Go runtime, required files, manifest, policy, Goose recipe schema, requirements/profile restrictions and architecture assets. fileciteturn196file0

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

The integration test covers host inventory → gateway/observability configuration → adapter matrix → prompt handoffs → Goose recipes → capability resolution → policy checks → session lifecycle → evidence hashing. Optional real provider test:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/integration.sh
```

VM mode validates the Lima recipe, starts disposable compute, checks Go/Node/npm plus guest instrumentation, then deletes the VM. Default CI does not require Lima. fileciteturn200file0

CI runs static, runtime and integration tests after installing Go, yq, ShellCheck and Goose. A disposable-VM pass is only established when VM mode is actually requested. fileciteturn199file0

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
├── policies/                   # policy definitions
├── recipes/
│   ├── experiments/            # researcher requirements
│   ├── profiles/               # capability registry + profiles
│   ├── agents/                 # Goose orchestration + adapter matrix
│   ├── gateway/                # mandatory model gateway
│   ├── observability/          # mandatory host observability
│   ├── host/                   # host tool inventory
│   ├── subrecipes/             # delegated research tasks
│   ├── lima/                   # disposable VM recipe
│   └── instrumentation/        # guest telemetry recipe
├── scripts/                    # installer, policy, lifecycle and tests
├── docs/architecture/          # Mermaid source + rendered architecture
├── manifest/                   # package/source-of-truth manifest
├── packages/                   # controlled workload fixtures
└── runs/                       # generated research sessions
```

## Design principle

> **Researchers declare intent and requirements. Agents select and operate capabilities. The Go API provides the capability boundary. Policy controls authority. Profiles define reusable infrastructure. Lima/QEMU contains execution. Evidence is preserved and independently verified.**
