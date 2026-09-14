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
| Go capability API | Resolve, provision, configure, execute, collect, destroy; operational install/validation/test entrypoints | `cmd/cusimanse/` |
| Roles/Skills | Specialist behavior and least-scope delegation | `recipes/agents/role-skill-registry.json` |
| Policy | Declarative authority and enforcement | `policies/host-policy.yaml` + Go runtime + `scripts/policyctl` |
| Agent | Plan, select, operate, observe, adapt, analyze | Goose + specialist roles |
| Containment | Disposable execution boundary | Lima/QEMU guest |
| Evidence | Observations, provenance, verification and report | `runs/<session-id>/` |

The agent may operate registered capabilities, but cannot create trusted profiles, mutate infrastructure recipes, expand policy scope, or execute an untrusted research workload on the host.

## Architecture

1. **Declaration** — Markdown contract plus YAML requirements.
2. **Agent operation** — Goose is the reference operator; roles and Skills provide specialist behavior.
3. **Capability resolution** — Go matches requirements to versioned profiles and fails closed on no match or ambiguity.
4. **Policy control** — Go owns lifecycle/control decisions and invokes `scripts/policyctl` for the current policy validation/check/approval compatibility surface.
5. **Execution** — the provider operates Lima/QEMU and fixed workload handlers inside disposable compute.
6. **Research** — evidence is collected and hashed, then analyzed, independently verified, reported and preserved.

```text
Researcher says WHAT
       ↓
Experiment requirements
       ↓
Agent selects WHICH registered capability
       ↓
Go Capability API owns lifecycle/HOW
       ↓
policy definition + policyctl enforcement helper
       ↓
Lima/QEMU provides WHERE
       ↓
Evidence + observability
       ↓
Specialists → verifier → report-generator
       ↓
preserve → destroy
```

**Policyctl evaluation:** it is still operationally required by the current Go runtime because `cmd/cusimanse` invokes it during policy validation/check/approval. It should be treated as a compatibility enforcement helper, not as a competing authority. A future native Go policy evaluator can remove this dependency; this branch does not falsely claim that migration is complete.

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

### 3. Install and diagnose through Go

After the one-time bootstrap path has provided Go, the Go CLI is the normal operational interface:

```bash
go run ./cmd/cusimanse install
cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
cusimanse doctor
```

The `install` command deliberately keeps `scripts/install.sh` as the bootstrap adapter because a fresh machine may not have Go yet. It then builds the Go CLI into `~/.local/bin/cusimanse`. `validate`, `preflight`, `test`, `integration-test`, `doctor` and `observability` are exposed through the Go CLI and currently delegate to the corresponding audited helpers. This is an incremental migration boundary: helper logic should move into native Go once equivalent coverage is established, rather than duplicating two implementations.

### 4. Start Goose

```bash
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

### 5. Resolve before execution

```bash
cusimanse resolve npm-threat-001
```

### 6. Approve and operate

```bash
cusimanse --approved run npm-threat-001
```

The lifecycle is `resolve → policy → provision → instrument → execute → collect → verify → report → preserve → destroy`.

### 7. Analyze, verify and report

The primary agent delegates runtime, forensics and detection analysis. The `verifier` independently checks evidence and conclusions. The `report-generator` creates the final report from requirements, preserved evidence, specialist analysis, verification and observability metadata.

## Host toolchain

The authoritative inventory is `recipes/host/security-research.yaml`. It separates common host commands, platform-specific host commands, guest-only instrumentation, mandatory gateways/observers and configuration locations.

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

`go` is a required host capability and is installed by `scripts/install.sh` on Linux and macOS. Numbat is installed with `go install`, so the Go toolchain is available before Go-based capabilities are installed.

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

Bootstrap remains:

```bash
./scripts/install.sh
```

Normal operation after Go is available:

```bash
cusimanse install
cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
cusimanse doctor
cusimanse observability status
```

Legacy helper commands remain supported and auditable while their implementation is migrated behind the Go API. The installer is idempotent, installs Go explicitly, configures gateways/observability, and fails before experiments when required host capabilities are unavailable.

## Gateway configuration

`recipes/gateway/mandatory.yaml` defines localhost-only OmniRoute and LiteLLM endpoints.

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

```bash
cusimanse observability status
cusimanse observability report <session-id>
```

See `docs/OBSERVABILITY.md` for correlation fields, access details and the report workflow.

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
cusimanse preflight
cusimanse validate
cusimanse test
cusimanse integration-test
```

Run a reference experiment:

```bash
cusimanse resolve npm-threat-001
cusimanse --approved run npm-threat-001
```

Compatibility wrapper:

```bash
./scripts/run-experiment.sh npm-threat-001
```

## Go capability API

The Go runtime is the agent-facing execution boundary and now exposes operational lifecycle/maintenance commands:

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
install
validate
preflight
test
integration-test
doctor
observability
```

Operational API mapping:

| Go command | Current implementation | Purpose |
|---|---|---|
| `install` | bootstrap helper + Go build | install/configure host and build CLI |
| `validate` | validation helper | static contracts, manifests, generated consumers, policy and recipe checks |
| `preflight` | preflight helper | host capabilities, mandatory services/configuration and profiles |
| `test` | runtime test helper | Go tests, lifecycle/evidence checks and profile resolution |
| `integration-test` | integration helper | cross-layer repository/control-plane validation; optional VM smoke path |
| `doctor` | validate + preflight | single diagnostic gate |
| `observability ...` | observability helper | status/report access |

This is intentionally a **single operational API with compatibility adapters**, not two competing implementations. The next hardening step is to migrate the deterministic validation/preflight logic into Go packages and retain shell only for OS/package-manager bootstrap and unavoidable external tools.

Examples:

```bash
go run ./cmd/cusimanse capability list
go run ./cmd/cusimanse capability skill list
go run ./cmd/cusimanse capability role list
go run ./cmd/cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
```

Role/Skill upserts update the source-of-truth registry and regenerate role YAML, Skill YAML and role/Skill bindings deterministically. They do not grant infrastructure authority or change policy.

## Roles Skills and learning

The managed source of truth is `recipes/agents/role-skill-registry.json`; generated role/Skill YAML lives under `.agents/agents/` and `recipes/skills/`. The generated binding contract is `recipes/agents/role-skill-bindings.yaml`.

### Learning loop

Learning is **disabled by default** and requires independent verification plus human approval before promotion.

## Profiles and requirements

The registry is deterministic, permits agent selection and forbids agent-created profiles. Resolution fails closed on no match or ambiguity. Host profiles forbid model-generated provisioning/instrumentation; workload profiles use fixed handlers and cannot be modified by the agent.

## Policy and safety

The policy definition remains declarative in `policies/host-policy.yaml`. The current Go runtime owns the capability lifecycle and invokes `scripts/policyctl` as its enforcement/approval compatibility helper. Therefore `policyctl` is still required for the current implementation, but it is **not a second policy authority**.

The intended future migration is a native Go evaluator over the same declarative policy file, followed by removal of the shell dependency after equivalent tests and independent verification.

## Evidence and reproducibility

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
cusimanse validate
```

Validates Go, recipes, manifests, role/Skill generated consumers, report generation, learning rules, observability configuration, policy, architecture assets and executable shell scripts.

### Runtime/control-plane validation

```bash
cusimanse test
```

Runs Go tests, policy checks, lifecycle/evidence checks and capability resolution. Optional VM smoke test:

```bash
CUSIMANSE_RUN_VM_TEST=1 cusimanse test
```

### Integration validation

```bash
cusimanse integration-test
```

The integration test covers host inventory → gateways/observability → adapters/prompts → Goose recipes → role/Skill management → learning contract → capability resolution → policy → session lifecycle → evidence hashing. VM mode validates the Lima recipe, checks guest Go/Node/npm/instrumentation and destroys the disposable VM.

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
├── cmd/cusimanse/              # Go capability API/runtime + operational API
├── contracts/                  # research contracts
├── prompts/experiments/        # agent-neutral prompt handoffs
├── policies/                   # declarative policy
├── recipes/                    # requirements, profiles, agents, gateways, observability, session and VM recipes
├── scripts/                    # bootstrap/compatibility helpers and tests
├── docs/architecture/          # Mermaid source + rendered architecture
├── docs/OBSERVABILITY.md       # observability/report access guide
├── manifest/                   # package/source-of-truth manifest
├── packages/                   # controlled workload fixtures
└── runs/                       # generated research sessions
```

## Design principle

> **Researchers declare intent and requirements. Agents select and operate capabilities. The Go API provides the capability boundary. Policy controls authority. Profiles define reusable infrastructure. Lima/QEMU contains execution. Evidence is preserved and independently verified.**
