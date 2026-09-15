# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-operated security research on disposable compute.** Cusimanse lets a researcher declare intent and requirements while an agent selects registered capabilities and operates them through a policy-controlled Go capability API.

![Cusimanse agent-operated capability architecture](docs/architecture/cusimanse-architecture.svg)

> **Flow:** Contract → requirements → agent → capability registry → Go runtime → policy → disposable VM → instrumentation/workload → evidence → specialist analysis → independent verification → report → preservation → destroy.

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
- [Runtime implementation and phases](#runtime-implementation-and-phases)
- [Platform support](#platform-support)
- [Repository map](#repository-map)

## What Cusimanse is

Cusimanse is a **declarative research-contract, YAML-recipe and agent-operation framework**. The researcher describes **what is required**, not how to build infrastructure.

| Layer | Responsibility | Source of truth |
|---|---|---|
| Contract | Purpose, scope, authorization, acceptance | `contracts/` |
| Requirements | OS, isolation, workload, network, instrumentation | `recipes/experiments/` |
| Capability registry | Reusable trusted host/workload capabilities | `recipes/profiles/registry.yaml` |
| Go runtime | Resolution, policy, lifecycle and capability boundary | `internal/`, `cmd/cusimanse/` |
| Roles/Skills | Specialist behavior and least-scope delegation | `recipes/agents/role-skill-registry.json` |
| Policy | Declarative authority and enforcement | `policies/host-policy.yaml` + `internal/policy/` |
| Agent | Plan, select, operate, observe, adapt, analyze | Goose + specialist roles |
| Containment | Disposable execution boundary | Lima/QEMU guest |
| Evidence | Observations, provenance, verification and report | `runs/<session-id>/` |

The agent may request registered capabilities, but cannot create trusted profiles, mutate infrastructure recipes, expand policy scope, or execute an untrusted research workload on the host.

## Architecture

1. **Declaration** — Markdown contract plus YAML requirements.
2. **Agent operation** — Goose is the reference operator; Summon delegates specialist analysis.
3. **Capability resolution** — Go resolves requirements against trusted registered profiles and fails closed on no match or ambiguity.
4. **Policy control** — Go evaluates the declarative policy and records decisions before controlled capabilities execute.
5. **Execution** — capability adapters operate Lima/QEMU and fixed workload handlers inside disposable compute.
6. **Research** — evidence is collected, hashed, independently verified, reported and preserved before destruction.

```text
Researcher says WHAT
       ↓
Experiment requirements
       ↓
Agent / Goose / Summon decides WHICH research step
       ↓
Cusimanse Go runtime decides WHETHER + HOW it may execute
       ├── profiles + execution plan
       ├── policy
       ├── capability registry
       ├── lifecycle
       └── evidence gate
       ↓
Lima/QEMU + workload + instrumentation
       ↓
evidence + observability
       ↓
Agent specialists → verifier → report
       ↓
preserve → destroy
```

> **Boundary rule:** the agent decides what research to do; Cusimanse decides whether and how that research may execute.

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

### 3. Bootstrap once, then use Go

```bash
./scripts/install.sh
cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
cusimanse doctor
```

`scripts/install.sh` is retained for OS/package-manager bootstrap. Deterministic validation, preflight and policy evaluation now live in Go packages. Shell helpers for those functions are compatibility wrappers only; shell remains for bootstrap, lifecycle compatibility and unavoidable external tools such as `limactl`.

### 4. Start Goose

```bash
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The recipe explicitly declares the `summon` platform extension. Summon delegation is orchestration/analysis only; capability execution remains behind Cusimanse.

### 5. Resolve before execution

```bash
cusimanse resolve npm-threat-001
```

### 6. Approve and operate

```bash
cusimanse --approved run npm-threat-001
```

The lifecycle is `resolve → policy → provision → instrument → execute → collect → verify → report → preserve → destroy`.

## Host toolchain

The authoritative inventory is `recipes/host/security-research.yaml`.

| Tool class | Examples | Boundary |
|---|---|---|
| Host/bootstrap | `git`, `bash`, `curl`, `go`, `python3` | bootstrap/operator |
| Data processing | `jq`, `yq`, `rg` | compatibility/external tooling |
| Agent | `goose` | agent orchestration |
| Virtualization | `limactl`, QEMU | controlled external capability |
| Guest instrumentation | `strace`, `tcpdump`, `ss`, `lsof`, `find`, `ps` | disposable guest |

Guest instrumentation is not treated as a host trust boundary. Full reference experiments run on Linux or a Linux guest through Lima/QEMU; Windows full experiments use WSL2.

## Gateway configuration

`recipes/gateway/mandatory.yaml` defines localhost-only OmniRoute and LiteLLM endpoints. Public MCP and public gateway access are denied by policy.

## Observability and reports

Cusimanse separates **agent observability** from **experiment evidence**:

> **Goose observes the agent; Cusimanse observes the experiment.**

| Tool | Purpose |
|---|---|
| Numbat | monitoring records |
| Phoenix | LLM/agent traces |
| OpenTelemetry | telemetry transport |
| ClawMetry | Goose session/token visibility |
| Aegis | independent observation |

Per-run telemetry lives under `runs/<session-id>/observability/`. Correlation fields include experiment_id, session_id, run_id, agent_id, role, skill, capability, workload_id, trace_id and timestamp. Never store API keys in telemetry artifacts.

## Agent adapters and prompt handoff

Goose is the **native reference operator**. Other agents are adapters over the same contracts, recipes and capability boundary.

| Agent | Command | Mode |
|---|---|---|
| Goose | `goose` | native recipe + Summon |
| OpenCode | `opencode` | prompt handoff |
| Hermes | `hermes` | prompt handoff |
| Antigravity | `agy` | prompt handoff |
| Pi | `pi` | prompt handoff |

Every adapter follows: read contract → validate scope → resolve → approval → operate through Cusimanse → observe → analyze → verify → report → preserve/destroy. Adapter prompts cannot grant authority or mutate trusted configuration.

## Quick start

```bash
./scripts/install.sh
cusimanse preflight
cusimanse validate
cusimanse test
cusimanse integration-test
cusimanse resolve npm-threat-001
cusimanse --approved run npm-threat-001
```

## Go capability API

The Go runtime is the agent-facing execution boundary:

```text
resolve → execution plan → policy → provision → configure → execute
        → collect → verify → report → preserve → destroy
```

Core runtime packages:

```text
internal/model/          typed runtime contracts
internal/policy/         declarative policy loading/evaluation/audit
internal/preflight/      deterministic host/profile preflight
internal/validation/     deterministic repository/control-plane validation
internal/execution/      execution plan and lifecycle engine
internal/capability/     capability contracts and registry
```

Operational commands:

```bash
cusimanse resolve <experiment>
cusimanse capability list
cusimanse capability skill list
cusimanse capability role list
cusimanse policy validate
cusimanse policy explain vm
cusimanse policy check vm
cusimanse policy require vm
cusimanse policy require vm --approved
cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
cusimanse doctor
```

`policyctl`, `preflight.sh` and `tests/validate.sh` remain callable for compatibility, but they now delegate to Go. They do not contain a second deterministic policy/validation implementation.

## Roles Skills and learning

The managed source of truth is `recipes/agents/role-skill-registry.json`; generated role YAML lives under `.agents/agents/`, Skills under `recipes/skills/`, and bindings under `recipes/agents/role-skill-bindings.yaml`.

Learning is **disabled by default** and requires independent verification plus human approval. Learned Skills cannot mutate the base contract, trusted profiles, execution boundary or security policy and cannot grant privileges automatically.

## Profiles and requirements

The researcher declares requirements; the agent selects a registered profile. The agent does not create trusted profiles.

```text
recipes/experiments/*.yaml          requirements
recipes/profiles/registry.yaml      trusted registry
recipes/profiles/host/*.yaml        reusable host capabilities
recipes/profiles/workload/*.yaml    fixed workload handlers
recipes/lima/security-research.yaml disposable compute
recipes/instrumentation/*.yaml      collectors
```

Resolution is deterministic and fails on no match or ambiguity. Host profiles prohibit model-generated provisioning/instrumentation and workload profiles use fixed handlers.

## Policy and safety

The authoritative policy is `policies/host-policy.yaml`. The native evaluator is `internal/policy/`; `scripts/policyctl` is only a compatibility wrapper.

```bash
cusimanse policy show
cusimanse policy validate
cusimanse policy explain vm
cusimanse policy check-all
cusimanse policy require vm
cusimanse policy require vm --approved
cusimanse policy enforce vm --approved
cusimanse policy audit
```

Decisions fail closed:

| Decision | Runtime behavior |
|---|---|
| `allow` / `allowed` / `controlled` | continue within declared boundary |
| `required` | required control is satisfied |
| `approval-required` | stop until explicit approval |
| `deny` / `denied` | stop; never bypass |

The policy denies credentials, unrestricted mounts, untrusted host execution, public MCP and public gateways; permits controlled Lima/QEMU and localhost services; and requires approval for selected privileged, VM, Git and learning operations. Evidence preservation and hashing are mandatory.

## Evidence and reproducibility

Evidence is collected inside disposable compute and must be preserved and hashed before destruction.

```text
runs/<session-id>/
├── session.yaml
├── evidence/
│   ├── index.yaml
│   └── audit/
│       ├── events.jsonl
│       └── manifest.sha256
├── provenance/manifest.sha256
├── analysis/summary.md
├── verification/result.md
├── research-report/{report.md,report.yaml}
├── preservation/manifest.yaml
└── observability/{token-usage.yaml,dashboard.yaml}
```

Model output is analysis, not raw evidence. Independent verification is required. Destruction is not allowed to precede successful evidence preservation.

## Reference experiments

| Experiment | Purpose |
|---|---|
| `go-install-001` | disposable Linux Go baseline |
| `npm-install-001` | pinned npm install with lifecycle disabled |
| `npm-lifecycle-001` | controlled local lifecycle execution |
| `npm-threat-001` | controlled adversarial-like lifecycle fixture |

The npm threat fixture is local and harmless and does not authorize credentials or external destinations.

## Validation and integration tests

### Validation

```bash
cusimanse validate
```

Validates project structure, contracts, recipes, manifests, generated role/Skill consumers, policy, architecture assets and forbidden marker leakage. The deterministic checks execute in Go.

### Preflight

```bash
cusimanse preflight
```

Checks platform, required host commands and required runtime/profile files. It does not silently install packages; bootstrap remains the installer responsibility.

### Functional runtime tests

```bash
cusimanse test
```

Runs `go test ./...` plus lifecycle, evidence, policy and profile-resolution checks. Optional Lima smoke validation is enabled with `CUSIMANSE_RUN_VM_TEST=1`.

### Integration

```bash
cusimanse integration-test
```

Covers host inventory → gateway/observability configuration → agent recipes → role/Skill management → learning contract → capability resolution → policy → session lifecycle → evidence hashing. VM mode additionally validates the Lima guest toolchain and destroys the disposable VM.

CI does not claim a VM pass unless VM mode actually runs.

## Runtime implementation and phases

The runtime is converging in six phases while preserving the agent/runtime boundary:

1. **Core contracts and safety** — typed models, policy, recipes, profiles, sessions and evidence.
2. **Execution engine** — immutable plans, capability registry, lifecycle state machine, cancellation and policy gates.
3. **Infrastructure adapters** — Lima/QEMU, fixed Go/npm workloads and guest instrumentation.
4. **Evidence and reproducibility** — collectors, provenance, hashing, independent verification and preservation gate.
5. **Agent integration** — Goose/Summon plus controlled adapters for other agents; learning remains gated.
6. **Cleanup and convergence** — remove duplicate registries and command interception, retain shell only for bootstrap and unavoidable external tools.

The detailed workstreams and invariants are documented in `docs/RUNTIME-IMPLEMENTATION.md` and `docs/AGENT-RUNTIME-BOUNDARY.md`.

## Platform support

| Platform | Support |
|---|---|
| Linux | full reference path |
| macOS | Lima/QEMU Linux guest |
| Windows 10/11 + WSL2 | supported Linux path |
| Native Windows | agent/repository fallback; full experiments require WSL2 |

## Repository map

```text
Cusimanse/
├── .agents/                    # agent roles
├── cmd/cusimanse/              # Go CLI/runtime
├── internal/                   # native Go control-plane packages
├── contracts/                  # research contracts
├── prompts/experiments/        # agent-neutral prompt handoffs
├── policies/                   # declarative policy
├── recipes/                    # requirements, profiles, agents and runtime recipes
├── scripts/                    # bootstrap/compatibility/external-tool helpers
├── docs/architecture/          # Mermaid + rendered architecture
├── docs/OBSERVABILITY.md       # observability guide
├── docs/OPERATOR-WORKFLOW.md   # operator workflow
├── docs/RUNTIME-IMPLEMENTATION.md # runtime phases and invariants
├── manifest/                   # package manifest
├── packages/                   # controlled workload fixtures
└── runs/                       # generated research sessions
```

## Design principle

> **Researchers declare intent and requirements. Agents select and operate capabilities. The Go API provides the capability boundary. Policy controls authority. Profiles define reusable infrastructure. Lima/QEMU contains execution. Evidence is preserved and independently verified.**
