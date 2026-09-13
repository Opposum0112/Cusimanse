# Agent-shell runtime runbook

Cusimanse is terminal-first. After bootstrap, the **selected primary agent shell is the operator**: it loads YAML contracts, plans, requests approval, orchestrates the VM lifecycle, executes approved workload actions, observes telemetry, collects evidence, invokes independent verification, reports, preserves evidence and destroys the disposable VM.

Host scripts are intentionally limited to prerequisite installation, configuration, validation and preflight. They are not a second orchestration controller.

## 0. Enter the repository

```bash
git clone <REPOSITORY_URL> Cusimanse
cd Cusimanse
git checkout architecture-refactor
```

## 1. Bootstrap and select exactly one primary

Interactive:

```bash
./scripts/prerequisites.sh
```

Non-interactive examples:

```bash
CUSIMANSE_PRIMARY_ADAPTER=grok-build ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=antigravity ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=pi ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=hermes ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=prime-intellect ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=codex ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=opencode ./scripts/prerequisites.sh
```

The selection is recorded at `.cusimanse/primary-agent.yaml`. Provider-managed candidates are not falsely marked available.

The canonical adapter registry is `recipes/agents/adapter-matrix.yaml`. It requires exactly one primary shell and records the native shell/prompt form for each adapter.

## 2. Validate before starting the agent

```bash
./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

Confirm the selected command:

```bash
cat .cusimanse/primary-agent.yaml
command -v <PRIMARY_COMMAND>
<PRIMARY_COMMAND> --help
```

The last command is intentionally provider-specific: use it to confirm the CLI syntax installed on the target host before runtime acceptance.

## 3. Native primary-shell commands

Do not translate one adapter's syntax into another. Use the selected adapter's native shell.

| Adapter | Interactive | Headless / run | Status |
|---|---|---|---|
| Goose | `goose` | `goose run --text '<PROMPT>'` | reference |
| OpenCode | `opencode` | `opencode run '<PROMPT>'` | candidate |
| Grok Build | `grok` | `grok -p '<PROMPT>'` | candidate |
| Antigravity | `agy` | `agy -p '<PROMPT>'` | candidate; verify with `agy --help` |
| Pi | `pi` | `pi -p '<PROMPT>'` | candidate |
| Hermes | `hermes` | TUI-first | candidate; use native interactive flow |
| Prime Agent | `prime-agent` | `prime-agent -p '<PROMPT>'` | candidate |
| Codex | `codex` | version-specific; verify with `codex --help` | candidate |
| Claude Code | `claude` | `claude '<PROMPT>'` | enterprise candidate |
| Devin | provider-managed | provider-managed | enterprise candidate |

The matrix is configuration, not proof of deployment. A CLI must pass host preflight and a disposable-VM end-to-end test before being considered runtime accepted.

## 4. Give the primary shell the shared contract

Start the selected shell, then provide this operator instruction:

```text
Operate this Cusimanse project from the primary-agent shell.
Load recipes/agents/primary-agent.yaml and recipes/agents/primary-shell.yaml.
Load recipes/agents/adapter-matrix.yaml, the selected adapter recipe, and the project
experiment contract.
Follow Discover → Validate → Preflight → Plan → Review → Approve → Provision →
Instrument → Execute → Collect → Reduce → Forensics → Independent verification →
Report → Preserve → Destroy.
Do not bypass policy, VM/OS controls, credentials, approvals or evidence integrity.
For privileged/destructive actions request approval before execution.
Do not claim PASS without runtime evidence and independent verification.
```

## 5. Non-destructive shell test

Before provisioning a VM, ask the primary shell:

```text
Load the Cusimanse primary-agent contract, adapter matrix and selected adapter recipe.
Report the selected adapter, contract paths, required approval gates, security boundary,
participating specialist roles, and expected evidence outputs. Do not modify the host,
VM, credentials or repository.
```

Expected result: the agent identifies the selected adapter, YAML contract, approval gates, evidence paths, specialist roles and VM/OS security boundary without privileged or destructive action.

## 6. Reference experiment: go-install-001

The primary shell should discover the actual case files and referenced recipes rather than assuming paths. The repository's reference case is:

```text
experiments/go-install-001/
recipes/experiments/go-install-001.yaml
```

Then execute the semantic lifecycle from the primary-agent contract. The primary shell may call declared repository scripts, but no second orchestrator should take ownership of the lifecycle.

Required outputs:

- runtime audit records;
- raw evidence and evidence index;
- findings/analysis;
- independent verification result;
- preservation/hash manifest before VM destruction;
- technical research report.

## 7. Adapter-specific smoke tests

### Grok Build

```bash
grok --version
grok inspect
grok -p 'Load recipes/agents/primary-agent.yaml and perform the non-destructive shell test. Do not modify anything.'
```

### Antigravity

```bash
agy --help
agy
```

Use the installed Antigravity prompt/agent mode to load the shared contract. Do not assume an IDE action is a security boundary.

### Pi

```bash
pi --help
pi -p 'Load the Cusimanse primary-agent contract. Perform only the non-destructive shell test.'
```

### Hermes

```bash
hermes --help
hermes
```

Hermes is TUI-first. Use its native interactive prompt flow to load the contract; do not rely on an undocumented one-shot flag.

### Prime Agent

```bash
prime-agent --help
prime-agent -p 'Load the Cusimanse primary-agent contract. Perform only the non-destructive shell test.'
```

### Codex

```bash
codex --help
codex
```

Use the installed version's documented non-interactive mode after confirming it with `codex --help`.

## 8. Runtime acceptance

A run is `PASS` only when all are true:

- the selected primary shell owned the lifecycle;
- the contract, adapter matrix and adapter recipe loaded;
- preflight passed;
- approvals were recorded for privileged/destructive actions;
- VM/OS controls enforced the boundary;
- instrumentation started before workload execution and ran against the workload inside the VM;
- raw evidence was collected;
- important findings were independently verified;
- evidence was hashed/preserved before destruction;
- final report and audit records exist;
- the run is reproducible from recorded inputs.

Otherwise use `PARTIAL`, `FAIL` or `NOT_DEPLOYED` according to the acceptance contract.
