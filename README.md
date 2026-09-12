# 🦝 Cusimanse

<p align="center">
  <img src="docs/images/cusimanse-mascot.svg" alt="Cusimanse mascot — curious cyber raccoon for security research" width="1000">
</p>

> **Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.**

Cusimanse is an **agent-neutral, terminal-first security research platform**. Exactly one selected primary agent shell owns the runtime operator, execution and orchestration cycle after bootstrap. YAML contracts define semantics; the agent shell operates them; Lima/QEMU and VM/OS controls enforce the security boundary.

[![CI](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml/badge.svg)](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml)

## 1. Primary-agent shell model

```text
Human / normal shell
      ↓
Bootstrap / prerequisites / selection / preflight
      ↓
SELECT ONE PRIMARY AGENT SHELL
      ↓
Discover → Validate → Plan → Review → Approve
      ↓
Provision → Instrument → Execute → Collect → Reduce
      ↓
Forensics → Independent verification → Report
      ↓
Preserve evidence → Destroy disposable VM
```

**The runtime operator and execution/orchestration cycle runs in the selected primary agent shell.** However, Cusimanse deliberately has two distinct command planes:

| Plane | Runs from | Responsibilities | Control relationship |
|---|---|---|---|
| **Normal shell / host shell** | User's ordinary terminal (`bash`, `zsh`, etc.) | Git, prerequisites, adapter selection, configuration, validation, preflight, `policyctl`, and host-side setup | **Outside agent control** |
| **Primary agent shell** | Selected agent (`goose`, `opencode`, `grok`, `agy`, `pi`, `codex`, `prime-agent`, etc.) | Load contracts/recipes, reason, plan, request approval, operate the experiment, execute approved workload, collect/reduce evidence, verify, report, preserve and destroy | **Agent-controlled runtime operator** |

### Important: `policyctl` is outside the agent control plane

`policyctl` intentionally runs from the **normal host shell**, independently of the selected agent. It is a host-side policy/configuration and token-observability utility; it is **not an agent tool, not an agent subcommand, not an orchestration controller, and not the VM security boundary**.

The separation is intentional:

```text
NORMAL HOST SHELL                         PRIMARY AGENT SHELL
─────────────────                         ───────────────────
./scripts/prerequisites.sh               goose / opencode / grok / agy / pi / ...
./scripts/agent-preflight.sh                         │
./policyctl validate                                  │
./policyctl ...                                       │
host configuration                                    │
                                                     │
                         ┌───────────────────────────┘
                         ↓
                  YAML contracts / recipes
                         ↓
                  Agent runtime lifecycle
                         ↓
              Lima/QEMU + VM/OS controls
                         ↓
                  Instrument / execute
                         ↓
                Evidence / verification
```

The primary agent **must not gain control of `policyctl`** or use it as a way to change host security policy. Policy decisions and host-side policy configuration remain outside the agent control plane. The actual isolation boundary remains the disposable VM plus VM/OS, filesystem/mount, privilege, credential and network controls.

### Command classification rule

When following this README, use these markers:

- **`[NORMAL SHELL]`** — type the command in your ordinary host terminal. This includes all `scripts/*.sh` commands and all `policyctl` commands.
- **`[AGENT SHELL]`** — enter the command/prompt in the selected primary agent's native terminal/interface.
- **`[AGENT PROMPT]`** — text supplied to the selected agent shell; it is not a host shell command.
- **`[BOTH / OBSERVE]`** — a normal-shell command used to inspect files/artifacts after the agent run.

Do not paste a `[NORMAL SHELL]` command into an agent prompt, and do not treat an `[AGENT PROMPT]` as a shell command.

## 2. Operator matrix

| Adapter | Interactive shell | Native prompt/run form | Role | Status |
|---|---|---|---|---|
| Goose | `goose` | `goose run ...` | reference operator | reference |
| OpenCode | `opencode` | `opencode run '<PROMPT>'` | programmable operator | candidate |
| Grok Build | `grok` | `grok -p '<PROMPT>'` | provider operator/orchestrator | candidate |
| Antigravity | `agy` | verify `agy --help` | provider operator | candidate |
| Pi | `pi` | `pi -p '<PROMPT>'` | thin custom operator | candidate |
| Hermes | `hermes` | TUI-first | self-improving operator | candidate |
| Codex | `codex` | verify `codex --help` | CLI/coding operator | candidate |
| Prime Agent | `prime-agent` | `prime-agent -p '<PROMPT>'` | self-improving operator | candidate |
| Claude Code | `claude` | provider/version-specific | enterprise operator | candidate |
| Devin | provider-managed | provider-managed | enterprise operator | candidate |

Do not copy Goose command syntax to another agent. Provider CLI versions are verified during preflight; recipe presence alone never means runtime deployment.

## 3. Five-minute repository validation

From a clean host/worktree:

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

The prerequisites script interactively selects exactly one primary agent. For repeatable testing, set it explicitly:

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=grok-build ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=antigravity ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=pi ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=hermes ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=prime-intellect ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=codex ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=opencode ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=goose ./scripts/prerequisites.sh
```

Selection is recorded in `.cusimanse/primary-agent.yaml`.

## 4. Verify the selected shell

```bash
# [NORMAL SHELL]
cat .cusimanse/primary-agent.yaml
command -v <PRIMARY_COMMAND>
<PRIMARY_COMMAND> --help
```

The help check is important because CLI flags are provider-specific and can change between releases.

Then launch the selected native agent interface:

```text
# [AGENT SHELL]
<PRIMARY_COMMAND>
```

The `<PRIMARY_COMMAND>` above means the selected agent from `.cusimanse/primary-agent.yaml`; it is not a literal command to copy unchanged.

## 5. Non-destructive smoke test

Start the selected native shell and provide:

```text
[AGENT PROMPT]
Operate this Cusimanse repository from the primary-agent shell.
Load recipes/agents/primary-agent.yaml and recipes/agents/primary-shell.yaml.
Load the selected adapter recipe.
Report the selected adapter, contract paths, approval gates, security boundary,
and expected evidence outputs. Do not modify the host, VM, credentials or repository.
Do not invoke policyctl or change host policy.
```

Expected: contract discovery and safety checks without privileged or destructive actions.

## 6. Runtime reference test

Use `experiments/go-install-001` as the common adapter-equivalence test. The primary shell loads:

```text
[AGENT SHELL / AGENT PROMPT]
experiments/go-install-001/experiment.yaml
experiments/go-install-001/lima.yaml
experiments/go-install-001/run.sh
```

Before the agent run, host policy validation remains a normal-shell operation:

```bash
# [NORMAL SHELL]
./policyctl validate
```

The agent then drives the experiment lifecycle without controlling `policyctl`:

```text
[AGENT SHELL]
Discover → Validate → Plan → Review → Approve
→ Provision VM → Start instrumentation → Execute workload
→ Collect → Reduce → Forensics → Independent verification
→ Report → Hash/preserve evidence → Destroy VM
```

Check artifacts after the run:

```bash
# [BOTH / OBSERVE — NORMAL SHELL]
find evidence blackboard experiments/go-install-001 -maxdepth 3 -type f -print
```

A runtime `PASS` requires runtime evidence, audit records, independent verification, a report and preservation before VM destruction. Configuration alone is never evidence.

## 7. Adapter-specific deployment and runtime commands

### Grok Build

Install/select:

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=grok-build ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
grok --help
grok inspect
```

Interactive:

```text
# [AGENT SHELL]
grok
```

Headless smoke test:

```bash
# [NORMAL SHELL — launches the selected agent interface; prompt executes in the agent]
grok -p 'Load recipes/agents/primary-agent.yaml and perform only the non-destructive Cusimanse contract check. Do not invoke policyctl.'
```

Grok's current documentation supports `grok -p` for headless scripting and `grok inspect` for discovered configuration. citeturn1search0turn1search2

### Antigravity

Install/select:

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=antigravity ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
agy --help
```

Interactive:

```text
# [AGENT SHELL]
agy
```

If the installed release supports the recorded prompt form, use it from the normal shell only as the mechanism that launches the agent:

```bash
# [NORMAL SHELL — launches the agent with an agent prompt]
agy -p 'Load the Cusimanse primary-agent contract and perform only the non-destructive contract check. Do not invoke policyctl.'
```

Because Antigravity CLI behavior is installation/version dependent in this project, `agy --help` is a required runtime check before claiming support.

### Pi

Install/select:

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=pi ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
pi --help
```

Interactive:

```text
# [AGENT SHELL]
pi
```

Print/smoke form:

```bash
# [NORMAL SHELL — launches the agent with an agent prompt]
pi -p 'Load the Cusimanse primary-agent contract and perform only the non-destructive contract check. Do not invoke policyctl.'
```

The prerequisites path uses the current Pi package name configured by the branch; verify the installed version with `pi --help` before runtime acceptance.

### Hermes

Install/select:

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=hermes ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
hermes --help
```

Interactive:

```text
# [AGENT SHELL]
hermes
```

Hermes is documented as a terminal UI/interactive CLI. Use its native interactive prompt flow to load the Cusimanse contract rather than depending on an undocumented one-shot flag. citeturn877file0L2-L2

### Prime Intellect / Prime Agent

Install/select:

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=prime-intellect ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
prime-agent --help
```

Interactive:

```text
# [AGENT SHELL]
prime-agent
```

Print/smoke form:

```bash
# [NORMAL SHELL — launches the agent with an agent prompt]
prime-agent -p 'Load the Cusimanse primary-agent contract and perform only the non-destructive contract check. Do not invoke policyctl.'
```

Prime Agent currently documents `-p/--print`, JSON/RPC modes, persistent sessions and evidence-bounded refinement. Its generated commands execute with user permissions, so Cusimanse still requires the external VM/OS security boundary. citeturn0search1turn0search2

### Codex

Install/select:

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=codex ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
codex --help
```

Interactive:

```text
# [AGENT SHELL]
codex
```

Use the installed Codex release's documented non-interactive mode only after checking `codex --help`. Do not infer Codex syntax from Goose or another adapter. Any one-shot invocation is a normal-shell launch of the agent, while the prompt and resulting lifecycle remain agent-side.

### OpenCode

Install/select:

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=opencode ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
opencode --help
```

Interactive:

```text
# [AGENT SHELL]
opencode
```

Non-interactive smoke test:

```bash
# [NORMAL SHELL — launches the agent with an agent prompt]
opencode run 'Load the Cusimanse primary-agent contract and perform only the non-destructive contract check. Do not invoke policyctl.'
```

OpenCode documents `opencode` for the TUI and `opencode run` for scripted/non-interactive use. citeturn1search1

### Goose reference

```bash
# [NORMAL SHELL]
CUSIMANSE_PRIMARY_ADAPTER=goose ./scripts/prerequisites.sh
./scripts/agent-preflight.sh
goose --help
```

Then:

```text
# [AGENT SHELL]
goose
```

Goose remains the reference adapter for equivalence testing, not a permanent architectural dependency.

## 8. Adapter equivalence

For each candidate adapter, compare the same `go-install-001` semantic run:

```text
[AGENT SHELL]
contract load
→ recipe load
→ experiment planning
→ approval
→ VM experiment
→ instrumentation
→ evidence preservation
→ independent verification
→ report
```

Host-side policy validation remains outside the agent:

```bash
# [NORMAL SHELL]
./policyctl validate
```

Keep Goose as the reference until the selected adapter demonstrates equivalent experiment semantics and acceptable audit/evidence output.

## 9. Evidence-bounded self-learning

```text
[AGENT SHELL]
verified run → compare → propose → validate/replay
→ independent verification → human approve → promote
```

Learning may improve reviewed non-security recipe defaults, routing hints, adapter command templates and evidence-reduction heuristics. It cannot modify VM isolation, credentials, privileges, network allowlists, approval requirements or evidence-integrity rules at runtime. It also cannot take control of `policyctl` or use `policyctl` to alter host security policy.

## 10. Architecture

![Cusimanse deployment architecture](docs/images/cusimanse-deployment-architecture.svg)

```text
NORMAL HOST SHELL
  ├── bootstrap / prerequisites / selection / validation
  └── policyctl (independent host-side policy/configuration + token observability)
                         │
                         │ policy state / validation result
                         ▼
PRIMARY AGENT SHELL
  ├── contracts / recipes
  ├── plan / approval / execution / orchestration
  ├── instrumentation / collection / verification
  └── report / preserve / destroy
                         │
                         ▼
              Lima / QEMU VM + OS controls
                         │
                         ▼
                 workload + instrumentation
                         │
                         ▼
                 evidence → verification
```

See `01-deployment-architecture.md` and `docs/agent-shell-runbook.md`.

## 11. CrewAI role-based analysis

CrewAI is a good fit as a **research-analysis layer**, not as the sole security controller. The selected primary agent retains lifecycle authority and may delegate specialist analysis to Planner, Static Analyst, Runtime Analyst, Network Analyst, Malware/RE Analyst, Detection Engineer, Forensics Analyst, Independent Verifier and Reporter roles. Privileged operations remain subject to the external host policy controls and Cusimanse approval/security boundary.

## 12. Recipes and contracts

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

## 13. Acceptance states

| State | Meaning |
|---|---|
| `PASS` | Runtime evidence and required verification demonstrate the capability |
| `PARTIAL` | Required coverage is incomplete |
| `FAIL` | Contract or safety requirement was violated |
| `NOT_DEPLOYED` | Provider/runtime/configuration is unavailable or unverified |

## 14. Security boundary

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
