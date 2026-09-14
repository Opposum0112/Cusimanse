# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-neutral security research on disposable compute.** Cusimanse separates research intent, experiment composition, agent operation, execution containment, instrumentation, evidence, and verification so the same experiment can be operated by different agents without duplicating the security workflow.

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

> **Architecture at a glance:** Contract → experiment configuration → Goose recipe / adapter handoff → primary agent → policy + disposable Lima/QEMU VM → guest instrumentation → workload → evidence → independent verification → report → preservation.

## Table of contents

- [What Cusimanse is](#what-cusimanse-is)
- [Architecture](#architecture)
- [Quick start](#quick-start)
- [Experiment model](#experiment-model)
- [Execution lifecycle](#execution-lifecycle)
- [Goose and specialist roles](#goose-and-specialist-roles)
- [Agent adapters](#agent-adapters)
- [Host, VM, and instrumentation](#host-vm-and-instrumentation)
- [Gateways and observability](#gateways-and-observability)
- [Skills and MCP](#skills-and-mcp)
- [Evidence and reproducibility](#evidence-and-reproducibility)
- [Threat-model coverage](#threat-model-coverage)
- [Validation](#validation)
- [Platform support](#platform-support)
- [Safety boundary](#safety-boundary)
- [Repository map](#repository-map)

## What Cusimanse is

Cusimanse is a **declarative research-contract and YAML-recipe framework for agent-operated security experiments on disposable compute**.

The design has five important separations:

| Layer | Responsibility | Source of truth |
|---|---|---|
| Research contract | Why the experiment exists, authorization, scope and acceptance | Contract Markdown/YAML |
| Experiment configuration | Workload, compute, policy, instrumentation, evidence and integrations | `recipes/experiments/*.yaml` |
| Agent handoff | How the selected agent receives the experiment | Goose recipe or prompt adapter |
| Execution | Where commands actually run and how they are observed | Lima/QEMU guest + runtime |
| Research output | Evidence, verification, report and provenance | `runs/<session-id>/` |

**Goose is the reference native operator.** OpenCode, Hermes, Antigravity and Pi are adapter targets; they do not get separate experiment definitions.

## Architecture

The architecture is intentionally layered rather than treating the agent, gateway, observability stack, or MCP as the security boundary.

### 1. Control and declaration plane

The researcher defines intent in a contract. Cusimanse then composes the concrete experiment: workload, disposable compute, policy, instrumentation, evidence requirements and integrations.

A valid Goose recipe is a **Goose-native handoff**, not a replacement for the Cusimanse experiment configuration. The prompt library serves the same handoff purpose for non-Goose agents.

### 2. Agent and orchestration plane

One selected primary agent owns the lifecycle. Goose uses its native recipe, Skills, Summon/delegation and MCP/extension mechanisms. Specialist roles are semantic responsibilities—planner, researcher, runtime analyst, forensics analyst, detection analyst, verifier and report generator—not a second orchestration engine.

### 3. Execution and security plane

The workload runs inside disposable Lima/QEMU compute. Policy gates scope, authorization, network/filesystem behavior and privileged or destructive actions. Guest instrumentation starts before the workload and records the observations needed for research.

### 4. Evidence and research plane

Raw observations become an evidence bundle with audit events, hashes and provenance. Specialist analysis is followed by an **independent verifier**, then the report and preservation metadata are produced before the VM is destroyed.

### 5. Integration and extension plane

Host capabilities, model gateways, observability, Skills and MCP extend the system. They do **not** replace the VM containment boundary. Optional learning is gated by replay, independent verification and human approval.

The editable source for the main architecture is `docs/architecture/cusimanse-architecture.mmd`; the rendered diagram is `docs/architecture/cusimanse-architecture.svg`.

## Quick start

### 1. Prepare the host

Linux, macOS with Lima, or WSL2:

```bash
./scripts/install.sh
```

Windows bootstrap:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

The installer is platform-aware and idempotent. Native Windows without WSL2 is an **agent-only fallback**, not a full Cusimanse experiment host.

### 2. Check readiness

```bash
./scripts/preflight.sh
./scripts/tools.sh check
./scripts/tests/validate.sh
./scripts/tests/runtime.sh
```

For a real disposable-VM smoke test:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

### 3. Select an experiment

Reference experiments intentionally use two separate files:

```text
recipes/<experiment>/recipe.yaml       # Goose-native handoff
recipes/experiments/<experiment>.yaml  # Cusimanse composition
```

Current examples:

```text
recipes/go-install-001/recipe.yaml
recipes/experiments/go-install-001.yaml

recipes/npm-install-001/recipe.yaml
recipes/experiments/npm-install-001.yaml

recipes/npm-threat-001/recipe.yaml
recipes/experiments/npm-threat-001.yaml
```

The Goose recipe contains the official recipe shape—`title`, `description`, and `instructions`/`prompt`. The companion Cusimanse YAML carries experiment-specific configuration.

### 4. Run through Goose

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The researcher starts the selected agent. The agent operates the lifecycle and executes the recipe-defined workload inside disposable compute; the researcher does not manually execute the workload on the host.

### 5. Review the run

```bash
cat runs/<session-id>/research-report/report.md
cat runs/<session-id>/verification/result.md
cat runs/<session-id>/analysis/summary.md
cat runs/<session-id>/evidence/index.yaml
cat runs/<session-id>/session.yaml
```

`research-report/report.md` is the primary researcher-facing output.

## Experiment model

A Cusimanse experiment is composed, not improvised:

```text
Research Contract
      ↓
Experiment Configuration
      ├── compute / Lima
      ├── workload
      ├── security policy
      ├── guest instrumentation
      ├── evidence requirements
      ├── specialist roles
      └── integrations
      ↓
Goose Recipe or validated agent adapter
      ↓
Selected Primary Agent
```

### Contract vs configuration vs recipe

- **Contract:** why, scope, authorization, acceptance and security constraints.
- **Experiment configuration:** the concrete research composition.
- **Goose recipe:** valid Goose-native instructions for operating that experiment.
- **Prompt reference:** a convenience handoff for agents that are not using native Goose recipes.

Keeping these separate prevents the same workload from being copied into multiple agent-specific formats.

## Execution lifecycle

The canonical lifecycle is:

```text
CREATE
  ↓
VALIDATE → PREFLIGHT → PLAN
  ↓
APPROVAL (when required)
  ↓
PROVISION VM
  ↓
START INSTRUMENTATION
  ↓
EXECUTE WORKLOAD
  ↓
COLLECT + HASH EVIDENCE
  ↓
ANALYZE
  ↓
INDEPENDENT VERIFY
  ↓
REPORT
  ↓
PRESERVE
  ↓
DESTROY VM
  ↓
COMPLETE / PARTIAL / FAILED
```

`scripts/session.sh` implements session-state/checkpoint and evidence/provenance mechanics. `scripts/run-experiment.sh` provides deterministic VM/evidence execution so lifecycle-critical mechanics are not left entirely to agent prose.

Lifecycle-critical stages remain sequential. Specialist analysis may be parallelized only after the relevant evidence exists, and the verifier is kept independent from the analysis it verifies.

## Goose and specialist roles

Goose is the reference operator because the platform can use native Goose recipes, Skills, delegation and MCP/extension capabilities without introducing a competing orchestration framework.

Specialist definitions live under `.agents/agents/` and include responsibilities for planning, research, runtime analysis, forensics, detection, verification and reporting.

`recipes/agents/goose-orchestration.yaml` maps those responsibilities to Goose-native delegation. A role describes **what** a specialist is responsible for; the orchestration recipe describes **when/how** it is delegated.

## Agent adapters

Compatibility and actual validation are deliberately separate:

| Agent | Integration path | Current status |
|---|---|---|
| Goose | Native Goose recipe | Reference operator; runtime evidence required for PASS |
| OpenCode | Prompt adapter | NOT_DEPLOYED |
| Hermes | Prompt adapter | NOT_DEPLOYED |
| Antigravity | Prompt adapter | NOT_DEPLOYED |
| Pi | Prompt adapter | NOT_DEPLOYED |

CLI presence, documentation, or schema compatibility is **not** runtime validation. An adapter becomes PASS only after disposable-VM execution produces the expected session artifacts and independent verification.

## Host, VM, and instrumentation

The host layer is responsible for platform-aware setup and preflight. Linux-specific forensic commands are guest instrumentation requirements, not universal host requirements.

```text
Host recipe
  ↓
platform-aware installer
  ↓
host preflight
  ↓
Lima / QEMU
  ↓
Linux guest
  ├── process observation
  ├── syscall observation
  ├── filesystem observation
  └── network observation
```

Apple Silicon can use native arm64 Lima/QEMU. Native x86_64 QEMU is not required for an arm64 guest. Full Windows experiments use WSL2 as the supported Linux host path.

## Gateways and observability

The full research deployment can integrate model gateways and agent observability:

- **Gateways:** OmniRoute → LiteLLM.
- **Observability:** Numbat, Aegis, Phoenix/OpenTelemetry and ClawMetry.
- **Credentials:** environment-only; not committed to recipes.
- **Network posture:** local-only by default.

These integrations observe or route agent activity. **They are not the workload containment boundary.** The disposable guest is the execution boundary.

CI control-plane validation does not require the full host observability stack.

## Skills and MCP

`recipes/skills/registry.yaml` and `recipes/mcp/registry.yaml` define capability sources.

Goose-native Skills and MCP extensions are preferred where they provide the required capability. External skill collections are treated as candidate sources rather than trusted code.

Promotion requires:

```text
candidate
  → scope/provenance review
  → execute
  → evaluate
  → replay
  → independent verification
  → human approval
  → skills/validated
```

MCP credentials remain environment-only, and MCP does not expand the VM/OS security boundary.

## Evidence and reproducibility

A completed session is expected to preserve enough information to explain **what ran, where it ran, what was observed, and how the conclusion was verified**.

Key artifacts include:

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
├── preservation/manifest.yaml
└── observability/
    ├── token-usage.yaml
    └── dashboard.yaml
```

Recipe digests, Git references, tool versions, agent/adapter versions, audit events and evidence hashes support reproducibility. Model output itself is not treated as raw evidence.

## Threat-model coverage

The reference experiments distinguish clean baselines from controlled adversarial-like behavior:

| Experiment | Purpose | Boundary |
|---|---|---|
| `go-install-001` | Go build/install baseline with runtime observation | Disposable guest |
| `npm-install-001` | Pinned npm installation baseline using `--ignore-scripts` | Disposable guest |
| `npm-lifecycle-001` | Controlled local postinstall fixture | Disposable guest; localhost-only attempt |
| `npm-threat-001` | Threat-model-oriented postinstall process/filesystem/network observation | Local, deterministic, disposable fixture |

The npm fixture is **adversarial-like, not real malware**. It does not receive credentials and is not authorized for external network access.

The following remain separate future experiments unless a run produces evidence for them: package substitution/supply-chain compromise, explicit network-policy violation, and agent tool-abuse or escape attempts.

## Validation

### Static validation

```bash
./scripts/tests/validate.sh
```

Checks project contracts, Goose recipe shape, experiment composition, adapter declarations, registries and policy invariants without requiring Lima or third-party observability services.

### Functional control-plane validation

```bash
./scripts/tests/runtime.sh
```

Exercises Goose recipe validation plus session lifecycle transitions, invalid-transition rejection, audit events and evidence/provenance hashing.

### Disposable-VM integration

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

A VM smoke-test PASS means the Lima/QEMU runtime path executed. A research experiment or adapter PASS additionally requires the expected session artifacts and independent verification.

## Platform support

| Platform | Support | Notes |
|---|---|---|
| Linux | Full | Reference host path |
| macOS | Full with Lima/QEMU | Guest provides Linux instrumentation |
| Windows 10/11 + WSL2 | Full supported path | Linux guest/host tooling runs through WSL2 |
| Native Windows | Limited | Agent-only fallback; not a full experiment host |

Recommended baseline: **4+ CPU cores, 8+ GB RAM, and 20+ GB free disk**, plus space for VM images and evidence.

## Safety boundary

The security boundary is intentionally explicit:

```text
Research contract
      │ defines authorization
      ▼
Policy + approval
      │ gates allowed actions
      ▼
Disposable Lima/QEMU guest
      │ contains workload execution
      ▼
Guest instrumentation
      │ records observations
      ▼
Evidence → independent verification → report
```

**Not the containment boundary:** agent adapters, Goose Skills, MCP, model gateways, observability services, or optional Container Use.

This architecture assumes experiments are authorized, local/disposable, and designed so that credentials and unintended external network access are excluded.

## Repository map

```text
Cusimanse/
├── .agents/
│   ├── agents/                 # specialist role definitions
│   └── skills/                 # agent skill definitions
├── contracts/                  # research intent and authorization
├── recipes/
│   ├── experiments/            # Cusimanse experiment composition
│   ├── agents/                 # agent/adapter declarations
│   ├── host/                   # platform-aware host requirements
│   ├── instrumentation/        # guest collection profiles
│   ├── lima/                   # disposable compute definitions
│   ├── mcp/                    # MCP registry
│   ├── observability/           # observability integrations
│   ├── session/                # lifecycle/session contract
│   └── skills/                 # skill registry
├── prompts/                    # cross-agent handoff prompts
├── scripts/                    # install, preflight and runtime mechanics
├── docs/architecture/          # editable Mermaid + rendered architecture
├── runs/                       # generated research sessions
└── packages/                   # controlled workload/support packages
```

## Design principle

> **Declare once. Operate with the selected agent. Execute only inside disposable compute. Observe before, during and after the workload. Preserve evidence. Verify independently. Learn only with replay and human approval.**
