# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-operated security research on disposable compute.** Cusimanse lets a researcher declare intent and requirements while an agent selects registered capabilities and operates them through a policy-controlled Go capability API.

![Cusimanse agent-operated capability architecture](docs/architecture/cusimanse-architecture.svg)

> **Flow:** Contract → requirements → agent → prompt handoff → capability registry → Go runtime → policy → disposable VM → instrumentation/workload → evidence → specialist analysis → independent verification → report → preservation → destroy.

## What Cusimanse is

Cusimanse is a **declarative research-contract, YAML-recipe and agent-operation framework**. The researcher describes **what is required**, not how to build infrastructure.

| Layer | Responsibility | Source of truth |
|---|---|---|
| Contract | Purpose, scope, authorization, acceptance | `contracts/` |
| Requirements | OS, isolation, workload, network, instrumentation | `recipes/experiments/` |
| Prompt library | Agent-neutral research handoff | `prompts/experiments/` |
| Operator guides | Thin adapter-specific handoff guidance | `prompts/operators/` |
| Capability registry | Reusable trusted host/workload capabilities | `recipes/profiles/registry.yaml` |
| Go runtime | Resolution, policy, lifecycle and capability boundary | `internal/`, `cmd/cusimanse/` |
| Roles/Skills | Specialist behavior and least-scope delegation | `recipes/agents/role-skill-registry.json` |
| Policy | Declarative authority and enforcement | `policies/host-policy.yaml` + `internal/policy/` |
| Agent | Plan, select, observe, analyze, delegate | Goose or an adapter |
| Containment | Disposable execution boundary | Lima/QEMU guest |
| Evidence | Observations, provenance, verification and report | `runs/<session-id>/` |

The agent may request registered capabilities, but cannot create trusted profiles, mutate infrastructure recipes, expand policy scope, or execute an untrusted research workload on the host.

## Architecture and authority boundary

1. **Declaration** — Markdown contract plus YAML requirements.
2. **Handoff** — the selected operator receives the shared experiment prompt and, for alternate operators, its thin operator guide.
3. **Agent operation** — Goose is the reference operator; Summon delegates specialist analysis.
4. **Capability resolution** — Go resolves requirements against trusted registered profiles and fails closed on no match or ambiguity.
5. **Policy control** — Go evaluates declarative policy and records decisions before controlled capabilities execute.
6. **Execution** — capability adapters operate Lima/QEMU and fixed workload handlers inside disposable compute.
7. **Research** — evidence is collected, hashed, independently verified, reported and preserved before destruction.

```text
Researcher says WHAT
       ↓
contract + experiment requirements
       ↓
shared experiment prompt: prompts/experiments/<experiment>.md
       ↓
selected operator
  ├── Goose native recipe + Summon
  └── OpenCode / Hermes / Antigravity / Pi adapter
       ↓
Cusimanse Go runtime decides WHETHER + HOW it may execute
       ├── trusted profiles + execution plan
       ├── policy + approval gates
       ├── capability registry
       └── lifecycle + evidence gates
       ↓
Lima/QEMU + workload + instrumentation
       ↓
evidence + observability
       ↓
specialist analysis → independent verification → report
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

### 3. Bootstrap and validate

```bash
./scripts/install.sh
cusimanse doctor
cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
```

`scripts/install.sh` is retained for OS/package-manager bootstrap. Deterministic validation, preflight and policy evaluation live in Go packages. Shell wrappers only delegate to Go; shell remains for bootstrap, lifecycle compatibility and unavoidable external tools such as `limactl`.

### 4. Select an operator

**Goose:**

```bash
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The Goose recipe explicitly declares the `summon` platform extension when it needs delegation. Summon is orchestration only; it cannot authorize infrastructure execution.

**Any other supported operator:** use the same experiment prompt plus its operator guide:

```text
prompts/experiments/npm-threat-001.md
prompts/operators/opencode.md
prompts/operators/hermes.md
prompts/operators/antigravity.md
prompts/operators/pi.md
```

The exact adapter CLI syntax may vary. The stable handoff inputs are the contract, experiment requirements, recipe references and shared prompt. The adapter must invoke Cusimanse for capability execution.

### 5. Resolve and approve

```bash
cusimanse resolve npm-threat-001
cusimanse policy explain vm
cusimanse policy check-all
# obtain explicit researcher approval when required
cusimanse policy require vm --approved
cusimanse --approved run npm-threat-001
```

Lifecycle: `resolve → policy → provision → instrument → execute → collect → verify → report → preserve → destroy`.

## Prompt library and alternate agent handoff

The **prompt library is a first-class repository artifact**, not an informal instruction copied into an agent session.

```text
prompts/
├── experiments/
│   ├── go-install-001.md
│   ├── npm-install-001.md
│   ├── npm-lifecycle-001.md
│   └── npm-threat-001.md
└── operators/
    ├── opencode.md
    ├── hermes.md
    ├── antigravity.md
    └── pi.md
```

For every alternate operator, the handoff is:

```text
contract
  + experiment YAML
  + session-state contract
  + prompts/experiments/<experiment>.md
  + prompts/operators/<operator>.md
          ↓
operator's native planning/tools/delegation
          ↓
Cusimanse Go capability API
          ↓
policy-controlled disposable execution
```

The shared experiment prompt is **agent-neutral**. The operator guide is deliberately thin and only explains how that operator consumes the handoff. Neither is an authority layer. The recipe remains the infrastructure source of truth, and the Go runtime/policy remains the execution authority.

See `docs/GOOSE-ADAPTERS.md`, `docs/AGENT-RUNTIME-BOUNDARY.md` and `recipes/agents/adapter-matrix.yaml` for the canonical handoff contract.

## Host toolchain

The authoritative inventory is `recipes/host/security-research.yaml`.

| Tool class | Examples | Boundary |
|---|---|---|
| Host/bootstrap | `git`, `bash`, `curl`, `go`, `python3` | bootstrap/operator |
| Data processing | `jq`, `yq`, `rg` | external tooling |
| Agent | `goose` | agent orchestration |
| Virtualization | `limactl`, QEMU | controlled external capability |
| Guest instrumentation | `strace`, `tcpdump`, `ss`, `lsof`, `find`, `ps` | disposable guest |

## Observability

Cusimanse separates **agent observability** from **experiment evidence**:

> **Goose observes the agent; Cusimanse observes the experiment.**

Mandatory/managed observers include Numbat, Phoenix, OpenTelemetry, ClawMetry and Aegis. Per-run telemetry lives under `runs/<session-id>/observability/` with experiment/session/run/agent/role/skill/capability/workload/trace correlation. Never store API keys in telemetry artifacts.

## Go capability API

The Go runtime is the agent-facing execution boundary:

```text
resolve → execution plan → policy → provision → configure → execute
        → collect → verify → report → preserve → destroy
```

Core packages:

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
cusimanse policy explain <action>
cusimanse policy check <action>
cusimanse policy check-all
cusimanse policy require <action> [--approved]
cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
cusimanse doctor
```

## Roles, Skills and learning

The managed source of truth is `recipes/agents/role-skill-registry.json`; generated role YAML lives under `.agents/agents/`, Skills under `recipes/skills/`, and bindings under `recipes/agents/role-skill-bindings.yaml`. Goose/Summon and alternate operators may select these specialist behaviors within declared scope.

Learning is **disabled by default** and requires independent verification, replay and human approval. Learned Skills cannot mutate the base contract, trusted profiles, execution boundary or security policy.

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

The authoritative policy is `policies/host-policy.yaml`; the native evaluator is `internal/policy/`. `scripts/policyctl` is only a compatibility wrapper.

Decisions fail closed. Credentials, unrestricted mounts, untrusted host execution, public MCP and public gateways are denied. Selected privileged, VM, Git and learning operations require approval. Evidence preservation and hashing are mandatory.

## Evidence and reproducibility

Evidence is collected inside disposable compute and must be preserved and hashed before destruction.

```text
runs/<session-id>/
├── session.yaml
├── evidence/{index.yaml,audit/{events.jsonl,manifest.sha256}}
├── provenance/manifest.sha256
├── analysis/summary.md
├── verification/result.md
├── research-report/{report.md,report.yaml}
├── preservation/manifest.yaml
└── observability/{token-usage.yaml,dashboard.yaml}
```

Model output is analysis, not raw evidence. Independent verification is required.

## Reference experiments

| Experiment | Purpose |
|---|---|
| `go-install-001` | disposable Linux Go baseline |
| `npm-install-001` | pinned npm install with lifecycle disabled |
| `npm-lifecycle-001` | controlled local lifecycle execution |
| `npm-threat-001` | controlled adversarial-like lifecycle fixture |

The npm threat fixture is local and harmless and does not authorize credentials or external destinations.

## Validation and integration tests

```bash
cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
```

Validation covers project structure, contracts, recipes, manifests, generated roles/Skills, policy, architecture assets, prompt handoff files and forbidden marker leakage. Integration covers host inventory, gateways/observability, policy decisions, adapter contracts, prompt library, Goose recipes, roles/Skills, learning controls, capability resolution, session lifecycle and evidence hashing. Set `CUSIMANSE_RUN_VM_TEST=1` for the optional disposable Lima smoke test.

CI must not claim a VM pass unless VM mode actually runs.

## Repository map

```text
Cusimanse/
├── .agents/                    # agent roles
├── cmd/cusimanse/              # Go CLI/runtime
├── internal/                   # native Go control-plane packages
├── contracts/                  # research contracts
├── prompts/experiments/        # shared agent-neutral experiment prompts
├── prompts/operators/          # alternate-agent handoff guides
├── policies/                   # declarative policy
├── recipes/                    # requirements, profiles, agents and runtime recipes
├── scripts/                    # bootstrap/compatibility/external-tool helpers
├── docs/architecture/          # Mermaid + rendered architecture
├── docs/GOOSE-ADAPTERS.md      # Goose/Summon and adapter handoff
├── docs/AGENT-RUNTIME-BOUNDARY.md
├── docs/OPERATOR-WORKFLOW.md
├── docs/RUNTIME-IMPLEMENTATION.md
├── manifest/                   # package manifest
├── packages/                   # controlled workload fixtures
└── runs/                       # generated research sessions
```

## Design principle

> **Researchers declare intent and requirements. Agents select and operate capabilities. The prompt library standardizes handoff. The Go API provides the capability boundary. Policy controls authority. Profiles define reusable infrastructure. Lima/QEMU contains execution. Evidence is preserved and independently verified.**
