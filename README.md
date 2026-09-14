# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-neutral security research on disposable compute.** Cusimanse separates research intent, experiment composition, agent operation, policy enforcement, execution containment, instrumentation, evidence, and verification.

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

> **Architecture at a glance:** Contract → experiment configuration → Goose recipe / adapter handoff → primary agent → policyctl + approval → disposable Lima/QEMU VM → guest instrumentation → workload → evidence → independent verification → report → preservation.

## Table of contents

- [What Cusimanse is](#what-cusimanse-is)
- [Architecture](#architecture)
- [Quick start](#quick-start)
- [Policy control and enforcement](#policy-control-and-enforcement)
- [Experiment model](#experiment-model)
- [Execution lifecycle](#execution-lifecycle)
- [Goose and specialist roles](#goose-and-specialist-roles)
- [Agent adapters](#agent-adapters)
- [Host, VM, and instrumentation](#host-vm-and-instrumentation)
- [Gateways and observability](#gateways-and-observability)
- [Skills and MCP](#skills-and-mcp)
- [Evidence and reproducibility](#evidence-and-reproducibility)
- [Threat-model coverage](#threat-model-coverage)
- [Validation and integration tests](#validation-and-integration-tests)
- [Platform support](#platform-support)
- [Safety boundary](#safety-boundary)
- [Repository map](#repository-map)

## What Cusimanse is

Cusimanse is a **declarative research-contract and YAML-recipe framework for agent-operated security experiments on disposable compute**.

| Layer | Responsibility | Source of truth |
|---|---|---|
| Research contract | Why, authorization, scope, acceptance and constraints | `contracts/` |
| Experiment configuration | Workload, compute, policy, instrumentation, evidence and integrations | `recipes/experiments/` |
| Policy enforcement | Allow, deny, approval-required decisions and audit | `scripts/policyctl` + `policies/` |
| Agent handoff | How the selected agent receives the experiment | Goose recipe / adapter |
| Execution | Where commands run and are observed | Lima/QEMU guest + runtime |
| Research output | Evidence, verification, report and provenance | `runs/<session-id>/` |

**Goose is the reference native operator.** Other agents remain adapter targets and do not get separate experiment definitions.

## Architecture

The architecture is layered so the agent, gateway, observability stack, Skills and MCP are not confused with the workload security boundary.

### 1. Control and declaration plane

The researcher defines intent in a contract. Cusimanse composes workload, compute, policy, instrumentation, evidence requirements and integrations.

### 2. Agent and orchestration plane

One selected primary agent owns the lifecycle. Goose uses native recipes, Skills, delegation and MCP/extensions. Specialist roles are semantic responsibilities, not a competing runtime.

### 3. Policy and execution plane

`policyctl` is the explicit policy control interface. It validates policy, evaluates actions, records decisions, and requires explicit approval for approval-gated operations. It is separate from the containment boundary: the disposable Lima/QEMU guest contains workload execution.

### 4. Evidence and research plane

Raw observations become an evidence bundle with audit events, hashes and provenance. Specialist analysis is followed by independent verification, reporting and preservation.

### 5. Integration and extension plane

Host capabilities, model gateways, observability, Skills and MCP extend the system. They do not replace the VM boundary. Learning remains gated by replay, independent verification and human approval.

Editable architecture sources:

- `docs/architecture/cusimanse-architecture.mmd`
- `docs/architecture/cusimanse-architecture.svg`

## Quick start

### 1. Prepare the host

```bash
./scripts/install.sh
```

Windows bootstrap:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

### 2. Check readiness

```bash
./scripts/preflight.sh
./scripts/tools.sh check
./scripts/policyctl validate
./scripts/tests/validate.sh
./scripts/tests/runtime.sh
```

For a real disposable-VM smoke test:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

### 3. Select and run an experiment

Each reference experiment has two definitions:

```text
recipes/<experiment>/recipe.yaml       # valid Goose-native handoff
recipes/experiments/<experiment>.yaml  # Cusimanse experiment composition
```

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The agent must use policy controls before provisioning or executing a workload.

### 4. Review the run

```bash
cat runs/<session-id>/research-report/report.md
cat runs/<session-id>/verification/result.md
cat runs/<session-id>/evidence/index.yaml
cat runs/<session-id>/session.yaml
```

## Policy control and enforcement

Policy is executable control-plane state, not documentation-only guidance.

```text
policies/host-policy.yaml       # host / privilege / VM / network / Git / orchestration / evidence
policies/mount-denylist.yaml    # paths never mounted into experiment VMs
policies/permission-tiers.yaml  # read / write / network / credential / privileged tiers
```

The canonical interface is `scripts/policyctl`:

```bash
# Inspect and validate
./scripts/policyctl show
./scripts/policyctl validate

# Evaluate and audit
./scripts/policyctl check vm
./scripts/policyctl check network
./scripts/policyctl check credentials
./scripts/policyctl check mounts
./scripts/policyctl check git-write

# Enforce: approval-required fails closed without explicit approval
./scripts/policyctl require vm
./scripts/policyctl require vm --approved
./scripts/policyctl enforce git-write
./scripts/policyctl enforce git-write --approved

# Review decisions
./scripts/policyctl audit
```

Controls include credentials, unrestricted mounts, host-root access, sudo, disposable VM/Lima/QEMU, localhost network, public MCP/gateway access, Git read/write/push, learning helpers, untrusted host execution and host network reconfiguration.

`policyctl` returns distinct states for invalid policy/action, denial, and approval-required operations. A deny is never converted into an allow by the agent. Decisions are written to an auditable JSONL file. Policyctl is a decision layer; Lima/QEMU remains the workload containment boundary.

## Experiment model

```text
Research Contract
      ↓
Experiment Configuration
      ├── compute / Lima
      ├── workload
      ├── policy → policyctl
      ├── guest instrumentation
      ├── evidence requirements
      ├── specialist roles
      └── integrations
      ↓
Goose Recipe or validated agent adapter
      ↓
Selected Primary Agent
      ↓
policyctl validation / checks / approval
      ↓
Disposable VM execution
```

- **Contract:** why, scope, authorization, acceptance and security constraints.
- **Experiment configuration:** concrete research composition.
- **Policy:** allowed, denied and approval-gated operations.
- **Goose recipe:** valid Goose-native instructions for operating the experiment.
- **Prompt reference:** convenience handoff for non-Goose agents.

## Execution lifecycle

```text
CREATE
  ↓
VALIDATE → PREFLIGHT → PLAN
  ↓
POLICY CHECKS → APPROVAL (when required)
  ↓
PROVISION VM → START INSTRUMENTATION
  ↓
EXECUTE WORKLOAD → COLLECT + HASH EVIDENCE
  ↓
ANALYZE → INDEPENDENT VERIFY → REPORT
  ↓
PRESERVE → DESTROY VM
  ↓
COMPLETE / PARTIAL / FAILED
```

`scripts/session.sh` implements lifecycle/checkpoint and evidence/provenance mechanics. `scripts/run-experiment.sh` provides deterministic VM/evidence execution. `scripts/policyctl` is the policy gate and audit interface.

## Goose and specialist roles

Goose is the reference operator because Cusimanse uses native Goose recipes, Skills, delegation and MCP/extension capabilities without requiring a competing orchestration framework.

Specialist definitions under `.agents/agents/` cover planning, research, runtime analysis, forensics, detection, verification and reporting. `recipes/agents/goose-orchestration.yaml` maps responsibilities to Goose-native delegation.

## Agent adapters

| Agent | Integration path | Current status |
|---|---|---|
| Goose | Native Goose recipe | Reference; runtime evidence required for PASS |
| OpenCode | Prompt adapter | NOT_DEPLOYED |
| Hermes | Prompt adapter | NOT_DEPLOYED |
| Antigravity | Prompt adapter | NOT_DEPLOYED |
| Pi | Prompt adapter | NOT_DEPLOYED |

CLI presence, documentation or schema compatibility is **not** runtime validation. Promotion requires disposable-VM execution and independent verification artifacts.

## Host, VM, and instrumentation

The host performs platform-aware setup and preflight. Linux-specific forensic commands are guest instrumentation requirements, not universal host requirements.

```text
Host recipe → installer → host preflight
                         ↓
                    Lima / QEMU
                         ↓
                    Linux guest
                  ↙      ↓       ↘
             process   syscall   filesystem/network
```

Apple Silicon can use native arm64 Lima/QEMU. Full Windows experiments use WSL2. Native Windows without WSL2 remains an agent-only fallback.

## Gateways and observability

Full research deployments can integrate OmniRoute → LiteLLM and Numbat, Aegis, Phoenix/OpenTelemetry and ClawMetry. Credentials remain environment-only and the default network posture is local-only.

These systems route or observe activity. **They are not the workload containment boundary.** CI control-plane validation does not require the full host observability stack.

## Skills and MCP

`recipes/skills/registry.yaml` and `recipes/mcp/registry.yaml` define capability sources. External skills are candidate inputs rather than trusted code.

```text
candidate → provenance/scope review → execute → evaluate → replay
→ independent verification → human approval → skills/validated
```

MCP credentials remain environment-only and MCP cannot expand the VM/OS security boundary.

## Evidence and reproducibility

A completed session preserves enough information to answer **what ran, where it ran, what was observed, which policy decisions were made, and how the conclusion was verified**.

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

Policy decisions are separately auditable through the configured policyctl JSONL audit file. Model output is not treated as raw evidence.

## Threat-model coverage

| Experiment | Purpose | Boundary |
|---|---|---|
| `go-install-001` | Go build/install baseline | Disposable guest |
| `npm-install-001` | Pinned npm baseline with `--ignore-scripts` | Disposable guest |
| `npm-lifecycle-001` | Controlled local postinstall fixture | Disposable guest; localhost-only |
| `npm-threat-001` | Threat-model-oriented lifecycle observation | Local, deterministic, disposable fixture |

The npm fixture is **adversarial-like, not real malware**. It does not receive credentials or external network authorization.

Package substitution/supply-chain compromise, explicit network-policy violation, agent tool abuse and agent escape remain separate future experiments unless independently exercised and evidenced.

## Validation and integration tests

### Static validation

```bash
./scripts/tests/validate.sh
```

Validates project structure, Goose recipes, experiment composition, policy files, `policyctl`, adapter declarations, registries, executable script bits and retired-reference invariants.

### Functional control-plane validation

```bash
./scripts/tests/runtime.sh
```

Exercises Goose recipe validation, lifecycle transitions, invalid-transition rejection, policy validation/check behavior, audit events and evidence/provenance hashing.

### Disposable-VM integration

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

The integration path validates the actual Lima/QEMU smoke test and policy-gated workload execution where supported. A research experiment or adapter PASS additionally requires independent verification.

## Platform support

| Platform | Support | Notes |
|---|---|---|
| Linux | Full | Reference host path |
| macOS | Full with Lima/QEMU | Guest provides Linux instrumentation |
| Windows 10/11 + WSL2 | Full supported path | Linux tooling through WSL2 |
| Native Windows | Limited | Agent-only fallback |

Recommended baseline: **4+ CPU cores, 8+ GB RAM, 20+ GB free disk**, plus VM/evidence storage.

## Safety boundary

```text
Research contract
      │ authorization / scope
      ▼
Policy + policyctl + approval
      │ allowed / denied / approval-gated actions
      ▼
Disposable Lima/QEMU guest
      │ workload containment
      ▼
Guest instrumentation
      │ observations
      ▼
Evidence → independent verification → report → preservation
```

**Not the containment boundary:** agent adapters, Goose Skills, MCP, model gateways, observability services or optional Container Use.

Policy control is a fail-closed decision layer, not a substitute for VM isolation. Credentials, unrestricted mounts, untrusted host execution and unauthorized external network access remain outside the intended experiment scope.

## Repository map

```text
Cusimanse/
├── .agents/                    # specialist roles and agent skills
├── contracts/                  # research intent, authorization and acceptance
├── policies/                   # executable policy, mount and permission definitions
├── recipes/                    # experiment, agent, host, instrumentation and integration declarations
├── prompts/                    # cross-agent handoff prompts
├── scripts/                    # installation, policy, preflight and runtime mechanics
├── docs/architecture/          # editable Mermaid + rendered architecture
├── runs/                       # generated research sessions
└── packages/                   # controlled workload/support packages
```

## Design principle

> **Declare once. Validate policy. Operate with the selected agent. Execute only inside disposable compute. Observe before, during and after the workload. Preserve evidence. Verify independently. Learn only with replay and human approval.**
