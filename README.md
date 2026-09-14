# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-neutral security research on disposable compute.** Cusimanse separates research intent, experiment composition, agent operation, policy enforcement, execution containment, instrumentation, evidence, and verification.

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

> **Architecture at a glance:** Contract → experiment configuration → host/workload profiles → Goose recipe / adapter handoff → primary agent → policyctl + approval → deterministic profile-selected runtime → disposable Lima/QEMU VM → declared instrumentation → workload → evidence → independent verification → report → preservation.

## Table of contents

- [What Cusimanse is](#what-cusimanse-is)
- [Architecture](#architecture)
- [Quick start](#quick-start)
- [Policy control and enforcement](#policy-control-and-enforcement)
- [Experiment model](#experiment-model)
- [Profiles and deterministic runtime](#profiles-and-deterministic-runtime)
- [Execution lifecycle](#execution-lifecycle)
- [Goose and specialist roles](#goose-and-specialist-roles)
- [Role-to-skill matrix](#role-to-skill-matrix)
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
| Experiment configuration | Profile composition, policy, evidence and integrations | `recipes/experiments/` |
| Host profile | Platform/capability selection and fixed runtime boundary | `recipes/profiles/host/` |
| Workload profile | Reusable workload identity and deterministic runtime handler | `recipes/profiles/workload/` |
| Policy enforcement | Allow, deny, approval-required decisions and audit | `scripts/policyctl` + `policies/` |
| Agent handoff | How the selected agent receives the experiment | Goose recipe / adapter |
| Execution | Where commands run and are observed | Lima/QEMU guest + deterministic runtime |
| Research output | Evidence, verification, report and provenance | `runs/<session-id>/` |

**Goose is the reference native operator.** Other agents remain adapter targets and do not get separate experiment definitions.

## Architecture

The architecture is layered so the agent, gateway, observability stack, Skills and MCP are not confused with the workload security boundary.

### 1. Control and declaration plane

The researcher defines intent in a contract. Cusimanse composes host and workload profiles with policy, evidence requirements and integrations.

### 2. Agent and orchestration plane

One selected primary agent owns the lifecycle. Goose uses native recipes, Skills, delegation and MCP/extensions. Specialist roles are semantic responsibilities, not a competing runtime.

### 3. Policy control plane

`policyctl` is the explicit policy control interface. It validates policy, evaluates actions, records decisions, and requires explicit approval for approval-gated operations.

### 4. Execution and security plane

The deterministic runtime resolves version-controlled profiles into a fixed execution path. The disposable Lima/QEMU guest remains the workload containment boundary.

### 5. Evidence and research plane

Raw observations become an evidence bundle with audit events, hashes and provenance. Specialist analysis is followed by independent verification, reporting and preservation.

### 6. Integration and extension plane

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

Each reference experiment has a research configuration plus reusable profiles:

```text
recipes/experiments/<experiment>.yaml       # composition
recipes/profiles/host/<profile>.yaml        # host/runtime boundary
recipes/profiles/workload/<profile>.yaml    # workload/runtime handler
recipes/<experiment>/recipe.yaml            # valid Goose-native handoff
```

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The agent selects profiles and operates the experiment, but cannot turn model output into an ad-hoc host provisioning or instrumentation system.

## Policy control and enforcement

Policy is executable control-plane state, not documentation-only guidance.

```text
policies/host-policy.yaml       # host / privilege / VM / network / Git / orchestration / evidence
policies/mount-denylist.yaml    # paths never mounted into experiment VMs
policies/permission-tiers.yaml  # read / write / network / credential / privileged tiers
```

The canonical interface is `scripts/policyctl`. It returns distinct states for invalid policy/action, denial, and approval-required operations. A deny is never converted into an allow by the agent. Decisions are written to an auditable JSONL file. Policyctl is a decision layer; Lima/QEMU remains the workload containment boundary.

## Experiment model

```text
Research Contract
      ↓
Experiment Configuration
      ├── host profile
      ├── workload profile
      ├── policy → policyctl
      ├── declared instrumentation
      ├── evidence requirements
      ├── specialist roles → role-specific Skills
      └── integrations
      ↓
Goose Recipe or validated agent adapter
      ↓
Selected Primary Agent
      ↓
policyctl validation / checks / approval
      ↓
Deterministic profile-selected runtime
      ↓
Disposable VM execution
```

- **Contract:** why, scope, authorization, acceptance and security constraints.
- **Host profile:** reusable platform/capability declaration selecting the fixed host/VM runtime path.
- **Workload profile:** reusable workload declaration selecting a fixed runtime handler and declared instrumentation.
- **Experiment configuration:** concrete research composition that references profiles rather than embedding infrastructure generation logic.
- **Policy:** allowed, denied and approval-gated operations.
- **Goose recipe:** valid Goose-native instructions for operating the experiment.
- **Role:** semantic responsibility assigned to a specialist agent/subagent.
- **Skill:** reusable procedure/capability selected by a role; it does not replace policy or VM containment.

## Profiles and deterministic runtime

Host and workload profiles make the runtime **parameterized without making it agent-generated**.

```text
                 Experiment
                /           \
               ▼             ▼
        Host Profile     Workload Profile
        platform/VM      handler/fixture
        fixed runtime    instrumentation
               \             /
                ▼           ▼
              Profile Resolver
                     │
               Policy Gate
                     │
                     ▼
          Deterministic Runtime
          ├── provision fixed VM recipe
          ├── configure declared instrumentation
          ├── execute fixed workload handler
          ├── collect/hash evidence
          └── teardown
```

The reference host profile is `recipes/profiles/host/linux-lima.yaml`. Reusable workload profiles currently cover Go install, pinned npm install, npm lifecycle, and the controlled npm threat fixture.

**The agent may select profiles and analyze evidence. It must not generate the canonical host provisioning script, VM definition, or instrumentation setup from model output.** `scripts/run-experiment.sh` resolves the declared profiles and accepts only registered deterministic workload handlers.

This gives Cusimanse reproducibility: the same contract, profile versions, recipe and runtime version resolve to the same execution topology and declared instrumentation, independent of which compatible agent performs the operation.

## Execution lifecycle

```text
CREATE
  ↓
VALIDATE → PREFLIGHT → PLAN
  ↓
SELECT PROFILES → POLICY CHECKS → APPROVAL
  ↓
RESOLVE FIXED RUNTIME → PROVISION VM → START DECLARED INSTRUMENTATION
  ↓
EXECUTE FIXED WORKLOAD HANDLER → COLLECT + HASH EVIDENCE
  ↓
ANALYZE → INDEPENDENT VERIFY → REPORT
  ↓
PRESERVE → DESTROY VM
  ↓
COMPLETE / PARTIAL / FAILED
```

`scripts/session.sh` implements lifecycle/checkpoint and evidence/provenance mechanics. `scripts/run-experiment.sh` provides deterministic profile-selected VM/evidence execution. `scripts/policyctl` is the policy gate and audit interface.

## Goose and specialist roles

Goose is the reference operator because Cusimanse uses native Goose recipes, Skills, delegation and MCP/extension capabilities without requiring a competing orchestration framework.

A **role defines responsibility; a Skill defines how that responsibility is performed**. Roles may select multiple Skills, and the same Skill can be reused by multiple roles. Policy enforcement is a cross-cutting control rather than a role-owned bypass path.

Specialist definitions under `.agents/agents/` cover planning, research, runtime analysis, forensics, detection, verification and reporting. `recipes/agents/goose-orchestration.yaml` is the source of truth for role-to-Skill assignment and Goose-native delegation.

### Role-to-skill matrix

| Specialist role | Primary responsibility | Skills used | Key outputs |
|---|---|---|---|
| Planner | Experiment planning, scope validation, lifecycle preparation | `experiment-run` | plan, scope/acceptance checks |
| Researcher | Research execution, observation synthesis, evidence interpretation | `experiment-run`, `evidence-analysis` | research findings, analysis inputs |
| Runtime analyst | Runtime behavior, process/syscall/network observation | `experiment-run`, `evidence-analysis` | runtime observations, behavioral findings |
| Forensics analyst | Filesystem/process artifacts, timelines, forensic analysis | `forensics`, `evidence-analysis` | forensic artifacts, timelines |
| Detection analyst | Indicators, detection hypotheses, security findings | `evidence-analysis` | detections, IOCs/behavioral findings |
| Verifier | Independent cross-checking, integrity, reproducibility | `verification`, `evidence-analysis` | verification result, integrity checks |
| Report generator | Synthesis, confidence, limitations, final research reporting | `evidence-analysis`, `verification` | report.md, report.yaml |

**Cross-cutting skills/control:** `scripts/policyctl` handles policy validation, checks, approval-gated enforcement and audit; `scripts/session.sh` handles lifecycle checkpoints, evidence hashing and provenance. Specialist roles cannot use Skills to bypass either boundary.

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
Host Profile → fixed host recipe → host preflight
                              ↓
                         Lima / QEMU
                              ↓
                         Linux guest
                              ↓
                 Workload Profile → declared instrumentation
                              ↓
                           workload
```

Apple Silicon can use native arm64 Lima/QEMU. Full Windows experiments use WSL2. Native Windows without WSL2 remains an agent-only fallback.

## Gateways and observability

Full research deployments can integrate OmniRoute → LiteLLM and Numbat, Aegis, Phoenix/OpenTelemetry and ClawMetry. Credentials remain environment-only and the default network posture is local-only.

These systems route or observe activity. **They are not the workload containment boundary.** CI control-plane validation does not require the full host observability stack.

## Skills and MCP

`recipes/skills/registry.yaml` and `recipes/mcp/registry.yaml` define capability sources. External skills are candidate inputs rather than trusted code.

```text
role → selects least-scope Skills → invokes tools/MCP through those Skills
→ produces role-specific artifacts → evidence bundle → independent verification
```

The role assignments above intentionally use the repository's current reusable Skills (`experiment-run`, `evidence-analysis`, `forensics`, `verification`). New specialist Skills can be added to `.agents/skills/` and promoted through the existing candidate/validated workflow.

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

Validates project structure, Goose recipes, experiment composition, host/workload profiles, deterministic handler restrictions, policy files, `policyctl`, adapter declarations, registries, executable script bits and retired-reference invariants.

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
Host + Workload Profiles
      │ fixed runtime resolution
      ▼
Deterministic Runtime
      │
      ▼
Disposable Lima/QEMU guest
      │ workload containment
      ▼
Declared guest instrumentation
      │ observations
      ▼
Evidence → independent verification → report → preservation
```

**Not the containment boundary:** agent adapters, Goose Skills, MCP, model gateways, observability services or optional Container Use.

**Not the canonical infrastructure generator:** the agent/model. Agents select and operate declared profiles; the deterministic runtime resolves them through fixed handlers and version-controlled recipes.

Policy control is a fail-closed decision layer, not a substitute for VM isolation. Credentials, unrestricted mounts, untrusted host execution and unauthorized external network access remain outside the intended experiment scope.

## Repository map

```text
Cusimanse/
├── .agents/                    # specialist roles and agent skills
├── contracts/                  # research intent, authorization and acceptance
├── policies/                   # executable policy, mount and permission definitions
├── recipes/
│   ├── experiments/            # experiment composition
│   ├── profiles/               # reusable host + workload profiles
│   ├── host/                   # host capability/toolchain recipe
│   ├── lima/                   # fixed disposable VM recipe
│   └── instrumentation/        # declared guest collector profile
├── prompts/                    # cross-agent handoff prompts
├── scripts/                    # installation, policy, preflight and runtime mechanics
├── docs/architecture/          # editable Mermaid + rendered architecture
├── runs/                       # generated research sessions
└── packages/                   # controlled workload/support packages
```

## Design principle

> **Declare once. Select reusable profiles. Validate policy. Operate with the selected agent. Resolve only through deterministic runtime handlers. Execute only inside disposable compute. Observe before, during and after the workload. Preserve evidence. Verify independently. Learn only with replay and human approval.**
