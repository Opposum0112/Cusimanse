# Cusimanse research workflow

This is the canonical operator workflow for a research session. The key rule is **where each action runs**:

- **Researcher / normal host shell:** repository setup, host installation, profile selection, validation, adapter preflight and starting the primary agent.
- **Primary agent prompt:** experiment planning, policy requests, approvals, specialist delegation, compute lifecycle, instrumentation orchestration, workload execution request, evidence collection, analysis, verification, reporting and session finalization.
- **Disposable compute / VM:** the actual target workload and VM-side instrumentation.
- **Control plane:** YAML contracts/recipes, session state, policyctl, audit, routing, orchestration, blackboard and observability.

The researcher does not manually type the lifecycle stages one by one after the primary agent starts.

## 1. Create the experiment — researcher + repository

**Run from the normal host shell, at the Cusimanse repository root.**

1. Write the Markdown research contract under `contracts/`.
2. Write the YAML experiment recipe under `recipes/experiments/`.
3. Reference workload, host, compute, tools, instrumentation, primary agent, roles, skills, MCP, orchestration, policy, routing, reporting and observability profiles.
4. Validate the recipe graph and contract.
5. Create `runs/<session-id>/session.yaml` from `recipes/session/session-state.yaml`.
6. Snapshot immutable experiment/contract/recipe references and all selected profiles.

The session YAML is the durable join key for the entire run.

## 2. Install and prepare the research host — normal shell

**Run these commands from the Cusimanse repository root in the research host's normal shell.**

```bash
cd <CUSIMANSE_REPO_ROOT>
git checkout architecture-refactor
./scripts/cusimanse-host.sh
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
./scripts/tests/validate-project.sh
```

The host profile is `recipes/host/research-host.yaml` and its declared tool inventory is `recipes/tools/security-research.yaml`.

Conceptually:

```text
researcher
  │ normal host shell
  ├─ install/prepare host tools
  ├─ validate policy
  ├─ select adapter
  └─ preflight adapter
       │
       ▼
   primary agent shell
```

**Do not run the experiment workload directly from this shell.** Host installation and validation are not the experiment execution plane.

## 3. Select one primary agent — normal shell

Use `recipes/agents/adapter-matrix.yaml`. Exactly one adapter becomes the session's primary operator.

Examples from the **normal host shell**:

```bash
# Goose
command -v goose && goose --help

# OpenCode
command -v opencode && opencode --help

# Grok Build
command -v grok && grok --help

# Antigravity
command -v agy && agy --help

# Pi
command -v pi && pi --help

# Hermes
command -v hermes && hermes --help

# Prime Agent
command -v prime-agent && prime-agent --help

# Codex
command -v codex && codex --help

# Claude Code
command -v claude && claude --help
```

Record the selected adapter and version in `session.yaml`. Do not assume that a documented CLI invocation is runtime accepted until it passes preflight and an end-to-end disposable-compute test.

## 4. Start the primary agent — normal shell, then switch to agent prompt

Starting the agent is a **normal host-shell action**. The lifecycle itself is then driven by the **agent prompt**.

Examples:

```bash
# Interactive Goose
cd <CUSIMANSE_REPO_ROOT>
goose

# OpenCode headless example
opencode run '<PROMPT>'

# Grok Build headless example
grok -p '<PROMPT>'

# Pi headless example
pi -p '<PROMPT>'

# Prime Agent headless example
prime-agent -p '<PROMPT>'

# Other interactive adapters
agy
hermes
codex
```

Use the adapter's native syntax from `recipes/agents/adapter-matrix.yaml`; never assume all adapters have the same prompt flag.

## 5. The experiment prompt — runs INSIDE the primary agent

The following is a **prompt, not a host-shell script**. Paste it into the selected primary agent after it starts. Replace the placeholders.

```text
You are the primary Cusimanse operator.

Session: <SESSION_ID>
Experiment: <EXPERIMENT_ID>
Repository: <CUSIMANSE_REPO_ROOT>

Load these control-plane inputs before doing anything:
- runs/<SESSION_ID>/session.yaml
- recipes/session/session-state.yaml
- the experiment recipe referenced by session.yaml
- the experiment's Markdown contract
- recipes/agents/primary-agent.yaml
- recipes/agents/primary-shell.yaml
- the selected adapter recipe
- the selected host, compute, tool, instrumentation, orchestration,
  policy, routing, audit, reporting and observability profiles

OPERATING RULES
- You are the primary lifecycle operator.
- Do not create a second lifecycle controller.
- Do not silently change the experiment contract or selected profiles.
- Do not bypass policy, approvals, credential controls or the compute/VM boundary.
- Model output is never evidence.
- Request human approval before privileged or destructive actions.
- Record requested, approved, executed and observed actions in the session audit.

PHASE 1 — DISCOVER AND VALIDATE
1. Read the session and experiment configuration.
2. Check every referenced recipe exists and record its digest/version.
3. Check the selected adapter and required tools are available.
4. Check policyctl validation and audit/evidence paths.
5. Check the declared network and credential policy.
6. Checkpoint session state and audit.

PHASE 2 — PLAN AND APPROVAL
1. Build an execution plan from the experiment recipe.
2. Identify workload, compute profile, instrumentation and evidence outputs.
3. Identify specialist roles and the declared orchestration backend.
4. Present the plan and safety boundary to the researcher.
5. Request explicit approval for required privileged/destructive actions.
6. Do not execute those actions before approval.

PHASE 3 — PROVISION AND INSTRUMENT
1. Provision the declared disposable Lima/QEMU compute profile.
2. Apply the declared VM/OS, mount, credential and network controls.
3. Start all required VM-side instrumentation BEFORE the workload.
4. Check instrumentation is producing telemetry.
5. Checkpoint session state.

PHASE 4 — EXECUTE
1. Execute only the workload declared by the experiment recipe.
2. Execute the workload INSIDE the disposable compute, not on the research host.
3. Capture stdout/stderr and declared process, syscall, filesystem, DNS/network,
   packet and security-event telemetry.
4. Record exact workload command, versions, timestamps and provenance.
5. Do not substitute an unapproved workload.

PHASE 5 — MULTIAGENT ANALYSIS
1. Delegate declared tasks to planner, researcher, runtime analyst, forensics,
   detection analyst, analysis agent, verifier and report generator as applicable.
2. CrewAI may coordinate specialist roles.
3. LangGraph may provide stateful graph/checkpoint execution.
4. Taskflow may decompose and track research tasks.
5. All specialist outputs must reference their inputs and evidence.
6. Specialist frameworks do not become security boundaries or lifecycle owners.

PHASE 6 — EVIDENCE AND VERIFICATION
1. Store raw evidence in the session artifact tree.
2. Update evidence/index.yaml and blackboard references.
3. Hash evidence and record provenance.
4. Reduce evidence deterministically before AI-assisted interpretation.
5. Independently verify important findings against preserved evidence.
6. Mark unsupported claims PARTIAL/FAIL rather than inventing evidence.

PHASE 7 — REPORT AND LEARNING
1. Write the research report with evidence references, versions, failures and
   observed-vs-inferred distinctions.
2. If a reusable improvement is discovered, create a learning candidate only.
3. Evaluate it against the contract.
4. Refine it, replay it on a distinct/frozen artifact, and independently verify it.
5. Request human approval before promotion to a validated skill/recipe improvement.
6. Roll back a promoted improvement if replay or safety evaluation regresses.

PHASE 8 — SESSION FINALIZATION
1. Stop/close runtime instrumentation cleanly.
2. Preserve and hash raw evidence BEFORE compute destruction.
3. Finalize audit and provenance manifests.
4. Finalize independent verification and research report.
5. Finalize token usage.
6. Write the session dashboard snapshot and clear/finalize the active session view.
7. Update session.yaml with final status, timestamps, artifact references and audit refs.
8. Only after preservation requirements are satisfied, destroy disposable compute.
9. Mark the session COMPLETE only when all required artifacts and controls exist;
   otherwise mark PARTIAL or FAILED with the reason.
```

## 6. Go experiment: exactly where to run it

### Normal host shell

```bash
cd <CUSIMANSE_REPO_ROOT>
./scripts/cusimanse-host.sh
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
```

Start the selected primary adapter from this shell, for example:

```bash
goose
```

Then paste the **Go experiment prompt** from `docs/prompts/go-install-001.md` into the agent.

### Primary agent

The agent reads:

```text
contracts/08-go-install-001.md
recipes/experiments/go-install-001.yaml
runs/<SESSION_ID>/session.yaml
```

It plans, obtains approval, provisions compute and starts instrumentation.

### Disposable compute / VM

The actual approved workload runs **inside the disposable compute**:

```bash
go install github.com/Opposum0112/ai-security-lab/packages/labprobe@v0.1.0
```

The source is copied into the VM according to the experiment recipe; networked module resolution is controlled/opt-in according to that recipe. Evidence and telemetry are collected from the VM before destruction.

## 7. npm experiment: exactly where to run it

### Normal host shell

```bash
cd <CUSIMANSE_REPO_ROOT>
./scripts/cusimanse-host.sh
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
```

Start the selected primary adapter, for example:

```bash
goose
```

Then paste the **npm experiment prompt** from `docs/prompts/npm-install-001.md` into the agent.

### Primary agent

The agent reads:

```text
recipes/experiments/npm-install-001.yaml
recipes/workloads/npm-install-001.yaml
runs/<SESSION_ID>/session.yaml
```

It plans, obtains approval, provisions compute, starts instrumentation and executes the declared npm workload.

### Disposable compute / VM

The actual npm installation/project bootstrap workload runs **inside the disposable compute** according to `recipes/workloads/npm-install-001.yaml`. Do not run `npm install` directly on the research host when executing this experiment.

## 8. Control-plane map

| Layer | Runs from | Responsibility |
|---|---|---|
| Research contract | repository | defines intent/scope/safety/evidence/acceptance |
| Experiment recipe | repository | composes workload + profiles |
| Session state | `runs/<session-id>/session.yaml` | durable state and profile snapshot |
| Host profile | repository | declares host tools/configuration |
| Normal host shell | research host | install/preflight/validate/start agent |
| Primary agent prompt | selected agent shell | owns research lifecycle |
| Specialist agents | selected agent/orchestration | analysis/forensics/detection/verification |
| policyctl | host control plane | policy decisions/token accounting; not sandbox |
| Orchestration | primary-agent controlled | Taskflow/LangGraph/CrewAI specialist coordination |
| Lima/QEMU + VM/OS | disposable compute | actual workload isolation boundary |
| Instrumentation | disposable compute | workload telemetry/evidence |
| Blackboard | session artifact plane | durable case/evidence references |
| Artifact store | `runs/<session-id>/` | raw evidence, audit, provenance, analysis, report, learning |
| Dashboard | session observability | token/session accounting and final snapshot |

## 9. Artifact store

```text
runs/<session-id>/
├── session.yaml
├── audit/
│   ├── events.jsonl
│   └── manifest.sha256
├── evidence/
│   ├── raw/
│   └── index.yaml
├── telemetry/
├── provenance/
│   └── manifest.sha256
├── blackboard/
├── analysis/
│   └── summary.md
├── verification/
│   └── result.md
├── research-report/
│   └── report.md
├── preservation/
│   └── manifest.yaml
├── observability/
│   ├── token-usage.yaml
│   └── dashboard.yaml
└── learning/
    ├── candidates/
    ├── evaluations/
    ├── replays/
    ├── verification/
    └── promotions/
```

Raw evidence is ground truth. Preserve and hash it before destroying disposable compute.

## 10. Learning and skill improvement

Learning is evidence-bounded and cannot silently modify the base experiment:

```text
prior cases / skills
      ↓
Taskflow decomposition
      ↓
primary-agent execution
      ↓
specialist analysis
      ↓
evaluate against contract
      ↓
refine candidate
      ↓
LangGraph checkpoint/replay
      ↓
independent verification
      ↓
human approval
      ↓
promote validated skill/recipe improvement
      ↓
rollback on regression
```

A learned skill cannot grant privilege, alter security policy, expose credentials, bypass approval or change the VM security boundary.

## 11. Session completion

Every session must finish with:

1. preserved/hash-verified evidence;
2. finalized audit/provenance;
3. independent verification;
4. research report;
5. finalized token accounting;
6. dashboard snapshot with no stale active session;
7. final `session.yaml` state;
8. compute destruction only after preservation.

Static configuration, adapter `--help`, or a successful host preflight is **not** runtime PASS.
