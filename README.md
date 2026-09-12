# 🦝 Cusimanse

<p align="center">
  <img src="docs/images/cusimanse-mascot.svg" alt="Cusimanse mascot — curious cyber raccoon for security research" width="1000">
</p>

> **Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.**

Cusimanse is an **agent-neutral, terminal-first security research platform**. The selected primary agent shell is the operator after bootstrap: it loads YAML contracts, plans, requests approval, orchestrates the VM lifecycle, executes approved actions, observes, collects evidence, verifies, reports, preserves and destroys. Host scripts are bootstrap/validation tools, not a second orchestration controller.

[![CI](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml/badge.svg)](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml)

## Primary-agent shell model

```text
Human / CI intent
      ↓
Markdown + YAML contracts
      ↓
Selected PRIMARY AGENT SHELL
      ↓
Discover → Validate → Preflight → Plan → Review → Approve
      ↓
Provision → Instrument → Execute → Collect → Reduce
      ↓
Forensics → Independent verification → Report
      ↓
Preserve evidence → Destroy disposable VM
```

**Important:** the entire operator, execution and orchestration cycle runs from the selected primary agent shell. `scripts/*.sh` prepare and validate the environment; they do not replace the primary agent or introduce a parallel controller.

The security boundary remains **Lima/QEMU + VM/OS controls**. Agents, prompts, skills, MCP, CrewAI and `policyctl` are not containment mechanisms.

## Operator matrix

| Adapter | Shell | One-shot / prompt form | Role | Status |
|---|---|---|---|---|
| Goose | `goose` | `goose run --text '<PROMPT>'` | reference operator | reference |
| OpenCode | `opencode` | `opencode run '<PROMPT>'` | programmable operator | candidate |
| Grok Build | `grok` | `grok -p '<PROMPT>'` | provider operator/orchestrator | candidate |
| Antigravity | `agy` | `agy -p '<PROMPT>'` | interactive/provider operator | candidate |
| Pi | `pi` | `pi -p '<PROMPT>'` | thin custom operator | candidate |
| Hermes | `hermes` | `hermes -z '<PROMPT>'` | self-improving operator | candidate |
| Codex | `codex` | `codex '<PROMPT>'` | CLI/coding operator | candidate |
| Prime Intellect | `prime-agent` | `prime-agent -p '<PROMPT>'` | self-improving operator | candidate |
| Claude Code | `claude` | `claude '<PROMPT>'` | enterprise operator | candidate |
| Devin | provider-managed | provider-managed | enterprise operator | candidate |

CLI syntax is adapter-specific and provider releases can change. Preflight must verify the installed command before claiming runtime availability.

## 5-minute repository validation

```bash
git clone <REPOSITORY_URL> Cusimanse
cd Cusimanse
git checkout agent-and-adapter

./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

The bootstrap presents an interactive primary-agent selection. For repeatable testing, select explicitly:

```bash
CUSIMANSE_PRIMARY_ADAPTER=grok-build ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=antigravity ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=pi ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=hermes ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=prime-intellect ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=codex ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=opencode ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=goose ./scripts/prerequisites.sh
```

Selection is recorded in `.cusimanse/primary-agent.yaml`. Provider/manual-managed candidates are reported as `NOT_DEPLOYED` rather than using an unverified installer.

## Runtime testing: one adapter at a time

### 1. Verify the selected shell

```bash
cat .cusimanse/primary-agent.yaml
command -v <PRIMARY_COMMAND>
<PRIMARY_COMMAND> --help
```

Run the adapter's native interactive shell. Do not wrap the lifecycle in another agent/controller.

### 2. Non-destructive smoke test

Give the selected shell this instruction:

```text
Operate this Cusimanse repository from the primary-agent shell.
Load recipes/agents/primary-agent.yaml and recipes/agents/primary-shell.yaml.
Load the selected adapter recipe.
Report the selected adapter, contract paths, approval gates, security boundary,
and expected evidence outputs. Do not modify the host, VM, credentials or repository.
```

Expected: contract/recipe discovery and safety checks, with no privileged or destructive operation.

### 3. Load the reference experiment

The primary shell must load:

```text
experiments/go-install-001/experiment.yaml
experiments/go-install-001/lima.yaml
experiments/go-install-001/run.sh
```

Then follow the common lifecycle:

```text
Discover → Validate → Preflight → Plan → Review → Approve
→ Provision VM → Start instrumentation → Execute workload
→ Collect → Reduce → Forensics → Independent verification
→ Report → Hash/preserve evidence → Destroy VM
```

### 4. Check outputs

```bash
find evidence blackboard experiments/go-install-001 -maxdepth 3 -type f -print
```

A runtime `PASS` requires audit records, runtime evidence, independent verification, a report and preservation before VM destruction. Configuration alone is never runtime `PASS`.

## Adapter-specific deployment and shell commands

### Grok Build

```bash
CUSIMANSE_PRIMARY_ADAPTER=grok-build ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
grok --help
grok
```

One-shot smoke form:

```bash
grok -p 'Load recipes/agents/primary-agent.yaml and perform only the non-destructive Cusimanse contract check.'
```

Then use the interactive `grok` shell for the full approved experiment lifecycle.

### Antigravity

```bash
CUSIMANSE_PRIMARY_ADAPTER=antigravity ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
agy --help
agy
```

Where supported by the installed release, the prompt form is:

```bash
agy -p 'Load the Cusimanse primary-agent contract and perform only the non-destructive contract check.'
```

Antigravity is provider/installation dependent; do not mark it deployed merely because the recipe exists.

### Pi

```bash
CUSIMANSE_PRIMARY_ADAPTER=pi ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
pi --help
pi
```

Smoke form:

```bash
pi -p 'Load the Cusimanse primary-agent contract and perform only the non-destructive contract check.'
```

Use Pi as the thin control loop while Cusimanse contracts and VM/OS controls define the lifecycle and boundary.

### Hermes

```bash
CUSIMANSE_PRIMARY_ADAPTER=hermes ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
hermes --help
hermes
```

The adapter records the intended prompt form as:

```bash
hermes -z 'Load the Cusimanse primary-agent contract and perform only the non-destructive contract check.'
```

Use the installed Hermes release's supported prompt mode if its CLI differs.

### Prime Intellect / Prime Agent

```bash
CUSIMANSE_PRIMARY_ADAPTER=prime-intellect ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
prime-agent --help
prime-agent
```

Smoke form:

```bash
prime-agent -p 'Load the Cusimanse primary-agent contract and perform only the non-destructive contract check.'
```

Treat self-improvement as a controlled research loop: checkpoint → compare → propose → validate → independent verification → human approval → promote.

### Codex

```bash
CUSIMANSE_PRIMARY_ADAPTER=codex ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
codex --help
codex
```

Load the YAML contract through the Codex adapter and keep all actions inside the declared approval/policy and disposable-VM boundary.

### OpenCode

```bash
CUSIMANSE_PRIMARY_ADAPTER=opencode ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
opencode --help
opencode
```

Smoke form:

```bash
opencode run 'Load the Cusimanse primary-agent contract and perform only the non-destructive contract check.'
```

### Goose reference

```bash
CUSIMANSE_PRIMARY_ADAPTER=goose ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
goose
```

Goose remains the reference adapter for equivalence testing; it is not a permanent architectural dependency.

## Adapter equivalence test

To replace Goose, run the same experiment with one selected adapter and compare:

```text
contract load
→ recipe load
→ policy check
→ shell smoke test
→ VM experiment
→ instrumentation
→ evidence preservation
→ independent verification
→ report
```

Keep Goose as the reference until the selected adapter demonstrates equivalent experiment semantics and acceptable audit/evidence output.

## Evidence-bounded self-learning

```text
observe → compare → propose → validate → independently verify
→ human approve → promote → checkpoint/rollback
```

Learning may improve non-security recipe defaults, adapter command templates, routing hints and evidence-reduction heuristics. It cannot modify VM isolation, credentials, privileges, network allowlists, approval requirements or evidence-integrity rules at runtime.

## Architecture

![Cusimanse deployment architecture](docs/images/cusimanse-deployment-architecture.svg)

The deployment architecture explicitly separates the **primary agent shell** from the **security boundary**:

```text
Contracts / recipes
       ↓
Primary agent shell
       ↓
policy + approval
       ↓
Lima / QEMU VM boundary
       ↓
workload + instrumentation
       ↓
evidence → verification → report
       ↓
preserve → destroy
```

See `01-deployment-architecture.md` and `docs/agent-shell-runbook.md`.

## CrewAI role-based analysis

CrewAI is a good fit as a **research-analysis layer**, not as the sole security controller. The selected primary agent retains lifecycle authority and can delegate analysis to Planner, Static Analyst, Runtime Analyst, Network Analyst, Malware/RE Analyst, Detection Engineer, Forensics Analyst, Independent Verifier and Reporter roles. Privileged operations return through the primary shell and Cusimanse approval/policy controls.

## Repository contracts and recipes

- `recipes/agents/primary-agent.yaml` — replaceable primary-agent contract
- `recipes/agents/primary-shell.yaml` — terminal-first operator/runtime contract
- `recipes/agents/learning-loop.yaml` — evidence-bounded learning
- `recipes/agents/adapter-matrix.yaml` — supported adapter matrix
- `recipes/adapters/` — provider-specific adapter contracts
- `recipes/agent-selection.yaml` — interactive/explicit primary selection
- `recipes/orchestration/` — orchestration strategies
- `recipes/mcp/` — MCP registry and connectors
- `recipes/skills/` — skills registry
- `recipes/reference/` — security tools/framework references
- `recipes/detection/` — detection validation
- `recipes/experiments/` — experiment contracts
- `docs/agent-shell-runbook.md` — granular terminal runtime test procedure
- `docs/agent-and-adapter-strategy.md` — adapter architecture and migration strategy

## Acceptance states

| State | Meaning |
|---|---|
| `PASS` | Runtime evidence and required verification demonstrate the capability |
| `PARTIAL` | Some required coverage is missing |
| `FAIL` | Contract or safety requirement was violated |
| `NOT_DEPLOYED` | Runtime/provider/configuration is unavailable or not verified |

## Security boundary

AI agents, prompts, skills, MCP servers, CrewAI and `policyctl` are **not** security boundaries. Enforcement comes from disposable VM/OS controls, filesystem/mount controls, credential separation, network controls and explicit approval gates.

Use only systems and workloads you are authorized to test. Preserve and hash evidence before destroying disposable VMs.

## Documentation

- `01-deployment-architecture.md` — deployment architecture
- `02-system-requirements.md` — host requirements
- `03-deployment-runbook.md` — deployment/runbook
- `04-security-model.md` — security model
- `05-multi-agent-operating-model.md` — multi-agent operation
- `06-observability-and-evidence.md` — observability and evidence
- `07-experiment-framework.md` — experiment framework
- `10-validation-and-acceptance.md` — validation and acceptance
- `11-current-antigravity-reference.md` — Antigravity reference
- `AGENTS.md` — agent operating instructions
- `SECURITY.md` — security boundaries and reporting

## License

**MIT License — Copyright (c) 2026 Opposum0112.** See `LICENSE`.
