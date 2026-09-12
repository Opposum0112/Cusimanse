# 🦝 Cusimanse

<p align="center">
  <img src="docs/images/cusimanse-mascot.svg" alt="Cusimanse mascot — curious cyber raccoon for security research" width="1000">
</p>

> **Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.**

Cusimanse is an **agent-neutral, terminal-first security research platform**. Exactly one selected primary agent shell owns the runtime operator, execution and orchestration cycle after bootstrap. YAML contracts define semantics; the selected agent operates them; Lima/QEMU and VM/OS controls provide the actual security boundary.

[![CI](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml/badge.svg)](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml)

## 1. Two command planes — read this first

Cusimanse deliberately separates the **normal host shell** from the **selected primary agent shell**. This applies to every supported agent.

```text
NORMAL HOST SHELL
  bootstrap → select agent → preflight → validate host policy
                         │
                         │ launch exactly ONE selected agent
                         ▼
PRIMARY AGENT SHELL
  load YAML → plan → approval → provision → instrument → execute
  → collect → verify → report → preserve → destroy
                         │
                         ▼
              Lima/QEMU + VM/OS controls
                         │
                         ▼
                     workload
```

| Plane | Where | Responsibilities | Does not own |
|---|---|---|---|
| **Normal shell** | User's `bash`/`zsh`/terminal | Git, prerequisites, agent selection, configuration, preflight, validation, `policyctl`, host setup and post-run inspection | Agent reasoning, experiment orchestration or runtime workload execution |
| **Primary agent shell** | Exactly one selected agent | Load contracts/recipes, plan, approval flow, operate VM experiment, instrument, execute workload, collect/reduce evidence, verify, report, preserve and destroy | Host policy control, `policyctl`, or the security boundary |

### `policyctl` is outside the agent control plane

`policyctl` runs from the **normal host shell**, independently of the selected agent. It is a host-side policy/configuration and token-observability utility. It is **not** an agent tool, agent subcommand, orchestration controller, or sandbox.

The primary agent must not take control of `policyctl` or use it to modify host security policy. The actual security boundary is the disposable VM plus VM/OS, filesystem/mount, privilege, credential and network controls.

### Command markers

- **`[NORMAL SHELL]`** — ordinary host terminal.
- **`[AGENT SHELL]`** — selected agent's native interface.
- **`[AGENT PROMPT]`** — instructions supplied to the agent, not a host command.
- **`[BOTH / OBSERVE]`** — normal-shell inspection of results after an agent run.

**Rule:** normal-shell setup commands never become agent commands, and agent prompts never become host policy commands.

## 2. All supported primary agents

Exactly **one** adapter is selected for a run. Goose is the reference adapter, not a permanent architectural dependency.

| Agent | Host check / launch | Agent shell | Prompt / headless form |
|---|---|---|---|
| **Goose** | `goose --help` | `goose` | `goose run ...` |
| **OpenCode** | `opencode --help` | `opencode` | `opencode run '<PROMPT>'` |
| **Grok Build** | `grok --help` | `grok` | `grok -p '<PROMPT>'` |
| **Antigravity** | `agy --help` | `agy` | Verify installed release before using prompt flags |
| **Pi** | `pi --help` | `pi` | `pi -p '<PROMPT>'` |
| **Hermes** | `hermes --help` | `hermes` | TUI-first; native interactive prompt |
| **Codex** | `codex --help` | `codex` | Use mode documented by installed release |
| **Prime Agent** | `prime-agent --help` | `prime-agent` | `prime-agent -p '<PROMPT>'` |
| **Claude Code** | `claude --help` | `claude` | Provider/version-specific |
| **Devin** | Provider setup/check | Provider-managed | Provider-managed |

Do not copy one agent's CLI syntax to another. Preflight verifies the installed/provider-supported command form. A recipe existing in the repository does **not** mean runtime support is deployed.

## 3. Common host preparation

```bash
# [NORMAL SHELL]
git clone <REPOSITORY_URL> Cusimanse
cd Cusimanse
git checkout agent-and-adapter

./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

`prerequisites.sh` interactively selects exactly one primary agent and records it in `.cusimanse/primary-agent.yaml`.

For repeatable selection:

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=goose ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=opencode ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=grok-build ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=antigravity ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=pi ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=hermes ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=codex ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=prime-intellect ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=claude-code ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=devin ./scripts/prerequisites.sh
```

Then:

```bash
# [NORMAL SHELL]
cat .cusimanse/primary-agent.yaml
command -v <PRIMARY_COMMAND>
<PRIMARY_COMMAND> --help
./policyctl validate
```

## 4. Launch the selected agent

The launch command is the boundary between the two command planes.

### Interactive mode — preferred

```text
[AGENT SHELL]
<PRIMARY_COMMAND>
```

Replace `<PRIMARY_COMMAND>` with the selected adapter. Once inside it, the **agent owns the experiment lifecycle**.

### Headless mode

Where supported, the normal shell may start the selected agent with an agent prompt:

```bash
# [NORMAL SHELL — launches the agent; the prompt and lifecycle remain agent-side]
<PRIMARY_HEADLESS_COMMAND> '<AGENT PROMPT>'
```

Starting an agent from the normal shell does **not** make the normal shell the experiment controller.

## 5. Non-destructive agent smoke test

After entering the selected agent:

```text
[AGENT PROMPT]
Operate this Cusimanse repository as the selected primary agent.
Load:
  recipes/agents/primary-agent.yaml
  recipes/agents/primary-shell.yaml
  the selected adapter recipe

Report the selected adapter, contract paths, approval gates, VM/OS security boundary,
and expected evidence outputs.
Do not modify host policy, credentials, or repository state.
Do not invoke policyctl. Do not bypass host or VM/OS controls.
```

Expected: contract discovery and safety checks only; no privileged or destructive operation.

## 6. How an experiment is actually run

The common reference experiment is `experiments/go-install-001`. The **selected agent**, not `policyctl` and not a host orchestration script, operates the experiment.

The agent loads:

```text
[AGENT SHELL / AGENT PROMPT]
experiments/go-install-001/experiment.yaml
experiments/go-install-001/lima.yaml
experiments/go-install-001/run.sh
```

Before starting, independently validate host policy:

```bash
# [NORMAL SHELL]
./policyctl validate
```

Then enter the selected agent and provide:

```text
[AGENT PROMPT]
Run experiment experiments/go-install-001.

Load and follow:
- recipes/agents/primary-agent.yaml
- recipes/agents/primary-shell.yaml
- the selected adapter recipe
- experiments/go-install-001/experiment.yaml
- experiments/go-install-001/lima.yaml
- experiments/go-install-001/run.sh

Follow this lifecycle:
1. Discover and validate the experiment contract.
2. Plan the run and identify approval requirements.
3. Obtain required human approval.
4. Provision the disposable Lima VM using the experiment recipe.
5. Start configured instrumentation.
6. Execute the approved workload inside the VM.
7. Collect and reduce runtime evidence.
8. Perform forensic analysis and independent verification.
9. Produce the report and audit record.
10. Hash/preserve evidence before VM destruction.
11. Destroy the disposable VM.

Do not invoke, modify, or bypass policyctl.
Do not weaken VM/OS, filesystem, mount, privilege, credential, network,
approval, or evidence-integrity controls.
```

Runtime ownership is:

```text
[AGENT SHELL]
Discover → Validate → Plan → Review → Approve
→ Provision VM → Instrument → Execute workload
→ Collect → Reduce → Forensics → Independent verification
→ Report → Preserve evidence → Destroy VM
```

`run.sh` is the **experiment/workload payload**. It is not the overall Cusimanse controller. The primary agent owns the surrounding lifecycle.

After the run:

```bash
# [BOTH / OBSERVE — NORMAL SHELL]
find evidence blackboard experiments/go-install-001 -maxdepth 3 -type f -print
```

A runtime `PASS` requires runtime evidence, audit records, independent verification, a report and preservation before VM destruction. Configuration alone is never evidence.

## 7. Agent-by-agent command guide

The experiment prompt in Section 6 is intentionally identical across adapters so their semantic behavior can be compared.

### 7.1 Goose

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=goose ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
goose --help
./policyctl validate
```

```text
[AGENT SHELL]
goose
```

Use the Section 6 experiment prompt. Goose is the reference operator.

### 7.2 OpenCode

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=opencode ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
opencode --help
./policyctl validate
```

```text
[AGENT SHELL]
opencode
```

Supported headless launch:

```bash
# [NORMAL SHELL — launches OpenCode; lifecycle remains agent-side]
opencode run '<PASTE THE SECTION 6 EXPERIMENT PROMPT HERE>'
```

### 7.3 Grok Build

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=grok-build ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
grok --help
grok inspect
./policyctl validate
```

```text
[AGENT SHELL]
grok
```

Supported headless launch:

```bash
# [NORMAL SHELL — launches Grok; lifecycle remains agent-side]
grok -p '<PASTE THE SECTION 6 EXPERIMENT PROMPT HERE>'
```

### 7.4 Antigravity

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=antigravity ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
agy --help
./policyctl validate
```

```text
[AGENT SHELL]
agy
```

Do not assume a prompt flag. If `agy --help` confirms a supported headless form, the normal shell may use it only to launch the agent; otherwise use the native interactive shell.

### 7.5 Pi

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=pi ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
pi --help
./policyctl validate
```

```text
[AGENT SHELL]
pi
```

Supported print launch:

```bash
# [NORMAL SHELL — launches Pi; lifecycle remains agent-side]
pi -p '<PASTE THE SECTION 6 EXPERIMENT PROMPT HERE>'
```

### 7.6 Hermes

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=hermes ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
hermes --help
./policyctl validate
```

```text
[AGENT SHELL]
hermes
```

Use Hermes' native interactive prompt flow for the Section 6 experiment unless the installed release explicitly documents another supported mode.

### 7.7 Codex

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=codex ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
codex --help
./policyctl validate
```

```text
[AGENT SHELL]
codex
```

Use only the non-interactive mode explicitly reported by the installed `codex --help`. Do not infer syntax from another adapter.

### 7.8 Prime Intellect / Prime Agent

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=prime-intellect ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
prime-agent --help
./policyctl validate
```

```text
[AGENT SHELL]
prime-agent
```

Supported print launch:

```bash
# [NORMAL SHELL — launches Prime Agent; lifecycle remains agent-side]
prime-agent -p '<PASTE THE SECTION 6 EXPERIMENT PROMPT HERE>'
```

Prime Agent commands execute with the user's permissions, so the external VM/OS boundary remains essential.

### 7.9 Claude Code — enterprise adapter

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=claude-code ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
claude --help
./policyctl validate
```

```text
[AGENT SHELL]
claude
```

Use the provider-supported Claude Code prompt/non-interactive form reported by the installed version. Do not assume flags from another adapter.

### 7.10 Devin — enterprise adapter

Devin is provider-managed rather than local CLI-first:

```text
[NORMAL SHELL]
Provider setup / authentication / runtime availability check
./policyctl validate
```

Then in the provider-managed session:

```text
[AGENT SHELL / AGENT PROMPT]
Use the Section 6 Cusimanse experiment prompt.
```

If the required runtime capability cannot be verified, record `NOT_DEPLOYED` rather than assuming support.

## 8. What runs where during a real experiment

| Step | Normal host shell | Primary agent shell |
|---|:---:|:---:|
| Clone/configure repository | ✓ | |
| Install prerequisites | ✓ | |
| Select exactly one adapter | ✓ | |
| Agent preflight | ✓ | |
| `policyctl validate` / host policy configuration | ✓ | **No** |
| Load experiment YAML | | ✓ |
| Load adapter/primary-shell contracts | | ✓ |
| Plan experiment | | ✓ |
| Request/handle required approval | | ✓ |
| Provision disposable VM | | ✓ |
| Start instrumentation | | ✓ |
| Execute workload | | ✓ |
| Collect/reduce evidence | | ✓ |
| Independent verification | | ✓ |
| Report/audit | | ✓ |
| Preserve/hash evidence | | ✓ |
| Destroy disposable VM | | ✓ |
| Inspect resulting artifacts | ✓ | ✓ during runtime |

This table is the authoritative command-plane distinction for the README.

## 9. Adapter equivalence

Every candidate primary should run the same semantic experiment:

```text
contract load → recipe load → experiment planning → approval
→ VM experiment → instrumentation → evidence collection
→ independent verification → report → preservation → destruction
```

Run host-side policy validation independently:

```bash
# [NORMAL SHELL]
./policyctl validate
```

Then run Section 6 through the selected agent. Keep Goose as the reference until another adapter demonstrates equivalent experiment semantics and acceptable audit/evidence output.

## 10. Evidence-bounded self-learning

```text
[AGENT SHELL]
verified run → compare → propose → validate/replay
→ independent verification → human approval → promote
```

Learning may improve reviewed non-security recipe defaults, routing hints, adapter command templates and evidence-reduction heuristics. It cannot modify VM isolation, credentials, privileges, network allowlists, approval requirements or evidence-integrity rules at runtime. It cannot take control of `policyctl` or use it to alter host security policy.

## 11. Architecture

![Cusimanse deployment architecture](docs/images/cusimanse-deployment-architecture.svg)

```text
NORMAL HOST SHELL
  ├── bootstrap / prerequisites / selection / validation
  ├── host configuration
  └── policyctl (independent host-side policy/configuration + token observability)
                              │
                              ▼
PRIMARY AGENT SHELL — exactly one
  ├── contracts / recipes
  ├── plan / approval / execution / orchestration
  ├── instrumentation / collection / verification
  └── report / preserve / destroy
                              │
                              ▼
                   Lima / QEMU VM + OS controls
                              │
                              ▼
                       workload + telemetry
                              │
                              ▼
                       evidence → verification
```

See `01-deployment-architecture.md` and `docs/agent-shell-runbook.md`.

## 12. CrewAI role-based analysis

CrewAI is a **research-analysis layer**, not the sole security controller. The selected primary agent retains lifecycle authority and may delegate specialist analysis to Planner, Static Analyst, Runtime Analyst, Network Analyst, Malware/RE Analyst, Detection Engineer, Forensics Analyst, Independent Verifier and Reporter roles.

## 13. Recipes and contracts

- `recipes/agents/primary-agent.yaml` — common operator contract
- `recipes/agents/primary-shell.yaml` — terminal-first shell contract
- `recipes/agents/learning-loop.yaml` — evidence-bounded learning
- `recipes/agents/adapter-matrix.yaml` — adapter matrix
- `recipes/adapters/` — provider-specific adapter contracts
- `recipes/agent-selection.yaml` — primary selection/preflight contract
- `recipes/orchestration/` — orchestration strategies
- `recipes/mcp/` — MCP registry/connectors
- `recipes/skills/` — skills registry
- `recipes/reference/` — tools/frameworks/research references
- `recipes/detection/` — detection validation
- `recipes/experiments/` — experiment contracts

## 14. Acceptance states

| State | Meaning |
|---|---|
| `PASS` | Runtime evidence and required verification demonstrate the capability |
| `PARTIAL` | Required coverage is incomplete |
| `FAIL` | Contract or safety requirement was violated |
| `NOT_DEPLOYED` | Provider/runtime/configuration is unavailable or unverified |

## 15. Security boundary

AI agents, prompts, skills, MCP servers and CrewAI are **not** security boundaries. `policyctl` is also **not** the sandbox boundary; it is deliberately kept outside the agent control plane as an independent host-side policy/configuration and token-observability utility. Enforcement comes from disposable VM/OS controls, filesystem/mount controls, credential separation, network controls and explicit approval gates.

Use only systems and workloads you are authorized to test. Preserve and hash evidence before destroying disposable VMs.

## Documentation

- `01-deployment-architecture.md` — deployment architecture
- `02-system-requirements.md` — host requirements
- `03-deployment-runbook.md` — deployment/runbook
- `04-security-model.md` — security model
- `05-multi-agent-operating-model.md` — multi-agent operation
- `06-observability-and-evidence.md` — observability/evidence
- `07-experiment-framework.md` — experiment framework
- `10-validation-and-acceptance.md` — validation and acceptance
- `11-current-antigravity-reference.md` — Antigravity reference
- `AGENTS.md` — agent operating instructions
- `SECURITY.md` — security boundaries/reporting

## License

**MIT License — Copyright (c) 2026 Opposum0112.** See `LICENSE`.
