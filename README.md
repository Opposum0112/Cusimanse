# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-operated security research on disposable compute.** Cusimanse lets a researcher declare intent and requirements while the selected agent plans, resolves capabilities, provisions, instruments, executes, observes and adapts the experiment through a policy-controlled Go capability API.

![Cusimanse agent-operated capability architecture](docs/architecture/cusimanse-architecture.svg)

> **Flow:** Contract → requirements → agent → capability registry → Go capability API → policy gate → disposable VM → instrumentation/workload → evidence → specialist analysis → independent verification → report → preservation → destroy.

## Table of contents

- [What Cusimanse is](#what-cusimanse-is)
- [Architecture](#architecture)
- [Researcher workflow](#researcher-workflow)
- [Quick start](#quick-start)
- [Go capability API](#go-capability-api)
- [Profiles and requirements](#profiles-and-requirements)
- [Policy and safety](#policy-and-safety)
- [Agent roles and Skills](#agent-roles-and-skills)
- [Evidence and reproducibility](#evidence-and-reproducibility)
- [Reference experiments](#reference-experiments)
- [Validation](#validation)
- [Platform support](#platform-support)
- [Repository map](#repository-map)

## What Cusimanse is

Cusimanse is a **declarative research-contract, YAML-recipe and agent-operation framework**. The researcher describes **what is required**, not how to build the infrastructure.

| Layer | Responsibility | Source of truth |
|---|---|---|
| Contract | Purpose, scope, authorization, acceptance | `contracts/` |
| Requirements | OS, isolation, workload, network, instrumentation | `recipes/experiments/` |
| Capability registry | Available host/workload capabilities | `recipes/profiles/registry.yaml` |
| Go capability API | Resolve, provision, execute, collect, destroy | `cmd/cusimanse/` |
| Policy | Allow, deny, approval and audit | `scripts/policyctl` + `policies/` |
| Agent | Plan, select, operate, observe, adapt, analyze | Goose + specialist roles |
| Containment | Disposable execution boundary | Lima/QEMU guest |
| Evidence | Raw observations, provenance, verification and report | `runs/<session-id>/` |

The agent is **allowed to provision and execute**. It does so through registered capabilities and policy controls rather than arbitrary model-generated infrastructure.

## Architecture

The architecture has six simple responsibilities:

1. **Declaration** — Markdown contract plus YAML requirements.
2. **Agent operation** — Goose is the reference operator; roles and Skills provide specialist behavior.
3. **Capability resolution** — the Go API matches requirements to versioned profiles and fails closed on no match or ambiguity.
4. **Policy control** — `policyctl` gates privileged, network, mount, credential and VM actions.
5. **Execution** — Go providers operate Lima/QEMU and fixed workload handlers inside disposable compute.
6. **Research** — evidence is collected and hashed, then analyzed, independently verified, reported and preserved.

### Agentic boundary

```text
Researcher says WHAT
       ↓
Requirements
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

The agent can make decisions and invoke capabilities repeatedly during a research session. The agent cannot create a new trusted infrastructure capability at runtime.

## Researcher workflow

The normal researcher experience is intentionally small:

### 1. Write the contract

Define the research question, authorization, scope, acceptance criteria and safety constraints in `contracts/<experiment>.md`.

### 2. Declare requirements

Edit only the experiment requirements in `recipes/experiments/<experiment>.yaml`:

```yaml
requirements:
  execution: disposable
  os: linux
  workload: npm
  network: localhost-only
  instrumentation:
    - process
    - syscall
    - filesystem
    - network
```

Do **not** describe VM commands, package installation or host mounts in the experiment file.

### 3. Start Goose

```bash
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The agent reads the contract and requirements, then resolves the capability set.

### 4. Inspect the resolution

```bash
go run ./cmd/cusimanse resolve npm-threat-001
```

Expected shape:

```text
host_profile: recipes/profiles/host/linux-lima.yaml
workload_profile: recipes/profiles/workload/npm-threat.yaml
```

### 5. Approve and operate

After the researcher explicitly approves approval-gated actions:

```bash
go run ./cmd/cusimanse --approved run npm-threat-001
```

The agent-operated API performs:

```text
resolve → policy → provision → instrument → execute → collect → hash
```

### 6. Research the evidence

The primary agent delegates specialist analysis and independent verification:

```text
runs/<session-id>/
├── evidence/
├── provenance/
├── analysis/
├── verification/
└── research-report/
```

### 7. Preserve and destroy

The agent must finish analysis, independent verification and preservation before destroying the disposable VM. A partial or unavailable capability is recorded rather than silently weakening the experiment.

## Quick start

### Install

```bash
./scripts/install.sh
```

Windows bootstrap:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

### Validate the installation

```bash
./scripts/preflight.sh
./scripts/tools.sh check
./scripts/policyctl validate
./scripts/tests/validate.sh
./scripts/tests/runtime.sh
```

### Run a reference experiment

```bash
go run ./cmd/cusimanse resolve npm-threat-001
go run ./cmd/cusimanse --approved run npm-threat-001
```

The compatibility wrapper remains available:

```bash
./scripts/run-experiment.sh npm-threat-001
```

It is now only a thin launcher for the Go capability runtime; the provisioning/execution implementation is no longer duplicated in shell.

## Go capability API

The Go runtime is the **agent-facing execution API**. It exposes a small capability vocabulary:

```text
resolve
provision
configure
execute
collect
destroy
run
```

Current CLI surface:

```bash
go run ./cmd/cusimanse capability list
go run ./cmd/cusimanse resolve <experiment>
go run ./cmd/cusimanse --approved run <experiment> [session-id]
```

The API separates the agent's decision from the infrastructure implementation:

```text
Agent request
    ↓
Capability resolver
    ↓
Registered profile
    ↓
Policy gate
    ↓
Provider / fixed handler
    ↓
Disposable compute
```

The initial provider uses Lima/QEMU. Additional providers can implement the same capability boundary later without changing research contracts.

**Important:** `--approved` is only for an action after explicit researcher approval. A policy denial is never converted to an allow by the agent.

## Profiles and requirements

Profiles are reusable platform capabilities, not per-experiment infrastructure scripts.

```text
recipes/profiles/
├── registry.yaml
├── host/
│   └── linux-lima.yaml
└── workload/
    ├── go-install.yaml
    ├── npm-install.yaml
    ├── npm-lifecycle.yaml
    └── npm-threat.yaml
```

The resolver uses the experiment requirements and the registry to select compatible profiles. It fails closed when there is no compatible profile or more than one compatible profile.

The agent may **select and operate** a profile. It may not create or mutate trusted profiles at runtime.

## Policy and safety

`policyctl` remains the single policy control surface:

```bash
./scripts/policyctl validate
./scripts/policyctl check vm
./scripts/policyctl check network
./scripts/policyctl check credentials
./scripts/policyctl check mounts
./scripts/policyctl require vm --approved
./scripts/policyctl audit
```

Policy controls cover credentials, mounts, host execution, VM access, network access, Git actions, gateways/MCP and evidence handling.

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

Agent adapters, Goose Skills, MCP, model gateways and observability are **not** the workload containment boundary.

## Agent roles and Skills

Goose remains the reference operator. Specialist roles are semantic responsibilities and reusable Skills provide their procedures.

| Role | Focus | Skills |
|---|---|---|
| Planner | Scope and experiment planning | `experiment-run` |
| Researcher | Execution and evidence interpretation | `experiment-run`, `evidence-analysis` |
| Runtime analyst | Runtime/process/syscall/network behavior | `experiment-run`, `evidence-analysis` |
| Forensics analyst | Filesystem/process artifacts and timelines | `forensics`, `evidence-analysis` |
| Detection analyst | Indicators and security findings | `evidence-analysis` |
| Verifier | Independent integrity and reproducibility | `verification`, `evidence-analysis` |
| Report generator | Findings, confidence and limitations | `evidence-analysis`, `verification` |

The policy and evidence controls remain cross-cutting and cannot be bypassed by a Skill.

## Evidence and reproducibility

A research run records what was requested, which profiles were resolved, what policy decisions occurred, what executed, what was observed and how the conclusion was verified.

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

Model output is analysis, not raw evidence. Final conclusions require independent verification.

## Reference experiments

| Experiment | Requirements | Purpose |
|---|---|---|
| `go-install-001` | disposable Linux Go | Go install/build baseline |
| `npm-install-001` | disposable Linux npm | Pinned npm install with lifecycle disabled |
| `npm-lifecycle-001` | disposable Linux npm + localhost-only | Controlled local postinstall |
| `npm-threat-001` | disposable Linux npm + localhost-only | Adversarial-like controlled lifecycle fixture |

The npm threat fixture is local and harmless, not real malware. It does not receive credentials or external network authorization.

## Validation

Static and runtime control-plane checks:

```bash
./scripts/tests/validate.sh
./scripts/tests/runtime.sh
```

Optional disposable-VM smoke test:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

Validation checks the Go capability runtime, registry, requirements, profile restrictions, policy, Goose recipes, lifecycle/evidence mechanics and architecture assets.

## Platform support

| Platform | Support |
|---|---|
| Linux | Full reference path |
| macOS | Lima/QEMU Linux guest |
| Windows 10/11 + WSL2 | Supported Linux path |
| Native Windows | Limited agent-only fallback |

## Repository map

```text
Cusimanse/
├── .agents/                    # agent roles and Skills
├── cmd/cusimanse/              # Go capability API/runtime
├── contracts/                  # research contracts
├── policies/                   # policy definitions
├── recipes/
│   ├── experiments/            # researcher requirements
│   ├── profiles/               # capability registry + profiles
│   ├── */recipe.yaml           # Goose handoffs
│   ├── host/                   # host capability recipe
│   ├── lima/                   # VM recipe
│   └── instrumentation/        # guest telemetry recipe
├── scripts/                    # thin compatibility, policy and lifecycle helpers
├── docs/architecture/          # Mermaid source + rendered architecture
├── manifest/                   # package manifest
├── packages/                   # controlled workload fixtures
└── runs/                       # generated research sessions
```

## Design principle

> **Researchers declare intent and requirements. Agents select and operate capabilities. The Go API provides the capability boundary. Policy controls authority. Profiles define reusable infrastructure. Lima/QEMU contains execution. Evidence is preserved and independently verified.**
