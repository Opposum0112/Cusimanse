# 🦝 Cusimanse

> **Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.**

**Architecture Refactor branch:** this branch adds stateful orchestration, Taskflow-style campaign recipes, self-learning primary-agent contracts, evidence-bounded skill promotion, additional tools and MCP profiles. **`main` is unchanged.**

## 1. What Cusimanse is

Cusimanse is an agent-neutral security research platform. It lets a researcher describe an experiment, select a primary terminal agent, provision a disposable Lima/QEMU VM, observe execution, collect evidence, verify findings and preserve artifacts before destruction.

It deliberately separates responsibilities:

```text
YAML recipe / campaign
        ↓
Taskflow-style task semantics
        ↓
LangGraph stateful execution
        ↓
Primary agent adapter
        ↓
Cusimanse experiment
        ↓
Lima + QEMU + VM/OS security boundary
        ↓
Evidence + telemetry + audit
        ↓
Case/evidence store
        ↓
Voyager-style skill learning
        ↓
SKILL.md + deterministic scripts
        ↓
Replay + independent verification + approval
        ↓
Validated skill library
```

### Core principle

> **Markdown specifies. YAML configures. Agent adapters operate. Policy constrains. Audit records. Evidence proves. Learning reuses only what has been verified.**

Cusimanse is a research platform, not a production malware sandbox or a claim of sandbox-escape resistance.

## 2. The architecture in simple terms

There are several different problems here. Do not solve them with one framework.

| Problem | Component | Meaning |
|---|---|---|
| Research definition | YAML | What should be investigated? |
| Workflow recipe | Taskflow-style YAML | What tasks happen and in what dependency order? |
| Runtime state | LangGraph | Where is this case in its execution graph? |
| Agent operation | Adapter | Which terminal agent performs the work? |
| Isolation | Lima/QEMU + VM/OS | Where can untrusted work execute? |
| Evidence | Run artifacts | What actually happened? |
| Case memory | Evidence/case store | What artifacts, findings and provenance exist? |
| Retrieval | Vector/semantic index | Which prior capabilities are relevant? |
| Learning | Voyager-style loop | How can a demonstrated procedure become reusable? |
| Skill package | SKILL.md + scripts | How is a reusable capability packaged? |
| Verification | Replay + independent check | Does the capability really work? |
| Governance | Human approval + policy | Should it be promoted or executed? |
| Tool access | MCP | Which scoped tools are exposed? |
| Host policy | `policyctl` | Host-side configuration and token observability |

No AI framework is the security boundary. The VM/OS, mounts, credentials, privilege and network controls are the security boundary.

## 3. Two command planes

### Normal host shell

Use the normal shell for Git, prerequisite installation, adapter selection, preflight, validation, `policyctl`, host setup and post-run inspection.

### Agent shell

The selected primary agent operates the experiment: loading contracts, planning, requesting approval, provisioning/operating the VM, instrumentation, workload execution, evidence collection, analysis, verification, reporting and preservation.

`policyctl` remains **outside the agent control plane**. It is not the orchestrator, sandbox, agent harness or enforcement boundary.

## 4. Where GitHub Security Lab Taskflow fits

GitHub Security Lab Taskflow is used as a **reference for YAML taskflow semantics**, not as the entire Cusimanse platform.

The useful idea is to represent a campaign as a sequence of reusable tasks, agent roles, dependencies, completion requirements, handoffs and approval points.

```text
Taskflow-style YAML
        ↓
   Campaign tasks
        ↓
    LangGraph
        ↓
  Case execution
```

Cusimanse adds the pieces Taskflow alone does not define for this project: disposable VM isolation, evidence provenance, verification, skill promotion and the existing agent-adapter contract.

Reference recipe: `recipes/workflows/security-research-taskflow.yaml`.

## 5. Where LangGraph fits

LangGraph is the **stateful execution layer**. It should track runtime state and checkpoints, not become the authoritative evidence archive.

Typical case state:

```text
case_id
campaign_id
current_node
current_hypothesis
retrieved_skills
tool_traces
execution_ids
pending_hitl
status
```

Typical graph:

```text
Discover → Validate → Retrieve → Plan → Review → Approve
→ Provision → Instrument → Execute → Collect → Analyze
→ Verify → Learn → Promote → Preserve → Destroy
```

The durable case/evidence store remains responsible for artifact identity, findings, execution records, verification and provenance.

## 6. Where Voyager-style learning fits

Voyager is a **learning pattern**, not a required runtime dependency.

The Cusimanse adaptation is:

```text
New task
   ↓
Retrieve relevant skills
   ↓
Execute selected capability
   ↓
Observe evidence
   ↓
Success? ── No ──→ refine candidate ──→ retry
   │
  Yes
   ↓
Create candidate skill
   ↓
Replay on distinct artifact
   ↓
Independent verification
   ↓
Human approval
   ↓
Versioned validated skill
   ↓
Index for future retrieval
```

A single successful LLM interaction does **not** automatically become trusted knowledge. Skills have provenance, capability metadata, evaluation history and promotion state.

### Skill package

```text
skills/
└── validated/
    └── evidence-pe-import-analysis/
        ├── SKILL.md
        ├── scripts/
        ├── references/
        └── eval/
```

`SKILL.md` describes the capability; deterministic scripts perform repeatable operations; references explain context; evaluation cases establish whether the capability works.

## 7. Self-learning primary adapters: Prime Agent and Hermes

Prime Agent and Hermes are optional **primary agent/operator adapters**. They can provide agent-native skills, memory, iterative work and self-improvement mechanisms. Cusimanse surrounds those capabilities with an evidence and promotion contract.

### Prime Agent

```text
Cusimanse campaign
       ↓
Prime Agent session
       ↓
Retrieve/use candidate skills
       ↓
Operate approved experiment in VM
       ↓
Capture traces + evidence
       ↓
Candidate capability
       ↓
Cusimanse replay/evaluation
       ↓
Independent verification
       ↓
Human approval
       ↓
Validated SKILL.md
```

Prime's own generated commands, subagents, memory or refinements are not evidence and do not bypass the VM boundary.

### Hermes

```text
Cusimanse case
       ↓
Hermes session
       ↓
Native skills/memory + retrieved Cusimanse skills
       ↓
Approved VM operation
       ↓
Evidence + execution trace
       ↓
Candidate skill
       ↓
Replay + independent verification
       ↓
Promotion gate
```

The same shared `recipes/agents/self-learning-primary.yaml` contract is used for both adapters. Installation/provider setup remains explicit and must be verified on the target host; credentials never belong in Git.

### Why this separation matters

Agent self-improvement asks: **“How can the agent become better at performing tasks?”**

Cusimanse institutional learning asks: **“What capability have we demonstrated strongly enough to preserve and reuse?”**

The second question requires evidence, provenance and verification.

## 8. Campaign example

`recipes/campaigns/security-research-learning.yaml` demonstrates the intended campaign model:

```yaml
id: security-research-learning
version: 1.0
kind: campaign
roles: [hunter, soc_analyst, detection_engineer, tool_integrator]
stages:
  - discover
  - retrieve
  - plan
  - approve
  - execute
  - collect
  - analyze
  - verify
  - learn
  - promote
promotion:
  minimum_validated_cases: 2
  minimum_distinct_artifacts: 2
  require_replay: true
  require_independent_verification: true
  require_human_approval: true
```

This keeps campaign semantics in YAML instead of hard-coding a monolithic Python workflow.

## 9. Evidence-bounded learning

A learned capability should be represented with relations such as:

```text
Artifact ──→ Finding
Artifact ──→ SkillCandidate
Skill ──→ Execution ──→ Artifact
Execution ──→ Verification
Skill ──→ validated_on / failed_on / derived_from
```

Promotion policy is defined in `recipes/learning/skill-promotion.yaml`.

Required gates include:

- two validated cases
- two distinct artifacts
- replay
- independent verification
- provenance
- capability manifest
- false-positive threshold
- human approval

Rejected candidates and failed evaluations remain recorded rather than silently disappearing.

## 10. MCP architecture

MCP provides scoped access to tools and research data. The Architecture Refactor profile is in `recipes/mcp/architecture-refactor.yaml`.

Conceptually:

```text
Agent
  ↓
MCP
  ├── repo/evidence access
  ├── VM control
  ├── policy information
  ├── ATT&CK/CVE/KEV enrichment
  ├── Sigma/YARA references
  └── observability
```

Security rules:

- stdio/local binding is preferred
- public exposure is denied
- privileged actions require approval
- secrets are never passed as MCP arguments
- external enrichment is cited and audited
- unknown integrations are `NOT_DEPLOYED`

MCP is a tool-access mechanism, not a security boundary.

## 11. Additional tool stack

The optional Architecture Refactor toolset can be requested with:

```bash
CUSIMANSE_INSTALL_ARCH_REFACTOR=1 ./scripts/prerequisites.sh
```

It attempts to install:

| Area | Tools |
|---|---|
| Core/runtime | Git, Bash, curl, Python, Go, Ruby, QEMU, Lima |
| Data/transform | jq, yq, ripgrep, SQLite |
| Binary analysis | file, binutils, strings/objdump, strace, lsof |
| Network | tcpdump, tshark/wireshark CLI |
| Detection | YARA where packaged |
| Stateful learning | LangGraph, PyYAML |
| Retrieval | Chroma and Qdrant Python clients |
| Observability | OpenTelemetry Python API/SDK |

The list is a capability inventory, not a requirement that every experiment use every tool. Missing optional components remain `NOT_DEPLOYED`.

Prime Agent and Hermes are deliberately explicit adapter installations rather than silently downloading model-agent runtimes or consuming credentials.

## 12. Repository structure

The Architecture Refactor adds dedicated locations without replacing the existing structure:

```text
Cusimanse/
├── .agents/
│   ├── agents/                  # agent role instructions
│   ├── skills/                  # reusable operator skills
│   └── mcp_config.json          # agent MCP configuration
├── recipes/
│   ├── agents/                  # primary-agent contracts
│   ├── campaigns/               # research campaign semantics
│   ├── experiments/             # experiment definitions
│   ├── install/                 # installation/bootstrap
│   ├── instrumentation/         # runtime instrumentation
│   ├── learning/                # skill learning/promotion
│   ├── lima/                    # VM profiles
│   ├── mcp/                     # MCP registries/profiles
│   ├── orchestration/            # execution engines
│   ├── routing/                 # adapter routing
│   ├── stages/                  # composable stages
│   ├── tools/                   # tool contracts
│   └── workflows/               # Taskflow-style workflows
├── skills/
│   └── validated/               # versioned validated capabilities
├── tools/
│   └── architecture-refactor/   # architecture tool inventory
├── experiments/
│   └── go-install-001/           # existing reference experiment
├── scripts/
│   ├── prerequisites.sh
│   └── tests/architecture-refactor.sh
├── cmd/policyctl/                # host-side policy utility
├── docs/
│   ├── architecture-refactor.md
│   └── runtime-architecture.md
└── README.md
```

The existing experiment and Goose path remain compatibility baselines.

## 13. Installation

### Baseline

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout architecture-refactor
./scripts/prerequisites.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

### Architecture Refactor optional stack

```bash
CUSIMANSE_INSTALL_ARCH_REFACTOR=1 ./scripts/prerequisites.sh
bash ./scripts/tests/architecture-refactor.sh
```

### Agent selection

```bash
export CUSIMANSE_PRIMARY_ADAPTER=goose
# or
export CUSIMANSE_PRIMARY_ADAPTER=prime-agent
# or
export CUSIMANSE_PRIMARY_ADAPTER=hermes
```

An adapter is not `PASS` merely because its name is configured. The CLI, provider and adapter contract must be available and exercised.

## 14. Runtime usage

### Phase A — normal shell

```bash
./policyctl validate
bash ./scripts/tests/architecture-refactor.sh
```

### Phase B — select and preflight the agent

Verify the selected CLI and provider configuration. Keep API keys outside Git.

### Phase C — load the campaign

The agent loads:

```text
recipes/campaigns/security-research-learning.yaml
recipes/workflows/security-research-taskflow.yaml
recipes/orchestration/langgraph.yaml
recipes/agents/self-learning-primary.yaml
```

### Phase D — retrieve skills

Candidate skills are filtered by capability metadata, risk tier, tool requirements and validation state. Retrieval ranking alone never grants authority.

### Phase E — execute

The primary agent operates the approved experiment. The workload executes inside the disposable VM. Instrumentation starts before execution where the experiment requires it.

### Phase F — evidence

Preserve raw artifacts, telemetry, audit records, reductions and verification records. Hash evidence before VM destruction.

Typical run layout:

```text
runs/<run-id>/
├── blackboard/
├── evidence/
├── telemetry/
├── audit/
├── reductions/
├── forensics/
├── verification/
├── reports/
└── manifest.json
```

### Phase G — learning

If the experiment reveals a reusable procedure, create a candidate skill. Evaluate it independently, replay it on a distinct artifact and request human promotion.

### Phase H — cleanup

Only after preservation and hashing should the disposable VM be destroyed.

## 15. Integration testing with the existing architecture

Run:

```bash
bash ./scripts/tests/architecture-refactor.sh
```

The integration validation checks:

1. new architecture files and contracts exist
2. shell syntax is valid
3. YAML contracts parse when PyYAML is available
4. Go formatting and `go vet` remain clean
5. the existing project validation still passes
6. `recipes/goose/project.yaml` remains referenced
7. `go-install-001` remains referenced
8. policyctl remains outside the agent control plane
9. Lima/QEMU remains the documented security boundary
10. independent verification remains a skill-promotion requirement

This is a **static/integration validation**, not a claim that a VM was booted. A runtime `PASS` requires actual execution and preserved evidence.

## 16. Acceptance states

| State | Meaning |
|---|---|
| `PASS` | Runtime behavior demonstrated with evidence |
| `PARTIAL` | Capability worked but coverage/evidence is incomplete |
| `FAIL` | Tested behavior did not meet the contract |
| `NOT_DEPLOYED` | Capability unavailable or intentionally disabled |
| `CANDIDATE` | Skill generated from evidence but not yet promoted |
| `VALIDATED` | Skill passed the required verification/promotion gates |

Configuration is not evidence. AI output is not evidence. Retrieval ranking is not validation.

## 17. Security model

```text
              Agent / LLM
                   │
             not a boundary
                   │
                   ▼
        ┌────────────────────┐
        │ Cusimanse workflow │
        └─────────┬──────────┘
                  │
                  ▼
        ┌────────────────────┐
        │ Lima / QEMU / VM   │  ← security boundary
        │ mounts             │
        │ credentials       │
        │ privilege         │
        │ network            │
        └─────────┬──────────┘
                  │
                  ▼
              Workload
```

Skills, prompts, MCP, vector stores, LangGraph and Taskflow are not isolation mechanisms.

Important invariants:

- untrusted workloads run in disposable VMs
- host credentials are not exposed to learned skills
- unrestricted host-root mounts are denied
- destructive/privileged actions require approval
- public MCP exposure is denied by default
- evidence is preserved before destruction
- important findings receive independent verification
- missing capabilities are reported as `NOT_DEPLOYED`

## 18. Documentation map

- `docs/architecture-refactor.md` — detailed architecture and responsibility boundaries
- `docs/runtime-architecture.md` — installation, runtime workflow and adapter operation
- `01-deployment-architecture.md` — deployment model
- `02-system-requirements.md` — requirements
- `03-deployment-runbook.md` — existing deployment/runbook
- `04-security-model.md` — security model
- `05-multi-agent-operating-model.md` — multi-agent operation
- `06-observability-and-evidence.md` — evidence/telemetry
- `07-experiment-framework.md` — experiment framework
- `08-go-install-001.md` — reference experiment
- `09-operations-and-maintenance.md` — operations
- `10-validation-and-acceptance.md` — validation
- `11-current-antigravity-reference.md` — Antigravity reference

## 19. Limitations

This branch is an architecture/integration refactor, not a security certification. CI/static validation cannot prove VM isolation or runtime sandbox resistance. Prime Agent, Hermes, LangGraph, vector retrieval and optional MCP integrations are not considered deployed until the target host actually exercises them. The existing Goose path remains the compatibility reference.

Use only systems and workloads you are authorized to test. Never commit provider keys, credentials, private workload data or unredacted forensic artifacts.

## License

MIT License — Copyright (c) 2026 Opposum0112. See `LICENSE` and `NOTICE`.
