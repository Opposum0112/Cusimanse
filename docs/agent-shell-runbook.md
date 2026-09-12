# Agent-shell runtime runbook

Cusimanse is terminal-first. After bootstrap, the **selected primary agent shell is the operator**: it loads the YAML contract, plans, requests approval, orchestrates the VM lifecycle, executes approved workload actions, observes telemetry, collects evidence, invokes independent verification, reports, preserves evidence and destroys the disposable VM.

Host scripts are intentionally limited to prerequisite installation, configuration, validation and preflight. They are not a second orchestration controller.

## 0. Enter the repository

```bash
git clone <REPOSITORY_URL> Cusimanse
cd Cusimanse
git checkout agent-and-adapter
```

## 1. Bootstrap and select one primary

Interactive:

```bash
./scripts/prerequisites.sh
```

Non-interactive examples:

```bash
CUSIMANSE_PRIMARY_ADAPTER=goose ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=grok-build ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=antigravity ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=pi ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=hermes ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=prime-intellect ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=codex ./scripts/prerequisites.sh
CUSIMANSE_PRIMARY_ADAPTER=opencode ./scripts/prerequisites.sh
```

The selection is recorded at `.cusimanse/primary-agent.yaml`. A provider-managed candidate is not falsely marked available.

## 2. Validate the host and repository

```bash
./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

Confirm the selected command before continuing:

```bash
cat .cusimanse/primary-agent.yaml
command -v <PRIMARY_COMMAND>
```

## 3. Start the primary agent shell

Use the adapter's native shell; do not translate it into another controller.

| Adapter | Interactive shell | One-shot form |
|---|---|---|
| Goose | `goose` | `goose run --text '<PROMPT>'` |
| OpenCode | `opencode` | `opencode run '<PROMPT>'` |
| Grok Build | `grok` | `grok -p '<PROMPT>'` |
| Antigravity | `agy` | `agy -p '<PROMPT>'` |
| Pi | `pi` | `pi -p '<PROMPT>'` |
| Hermes | `hermes` | `hermes -z '<PROMPT>'` |
| Prime Intellect | `prime-agent` | `prime-agent -p '<PROMPT>'` |
| Codex | `codex` | `codex '<PROMPT>'` |

> CLI flags are adapter-specific. Treat these as the contract's intended shell forms and verify the installed provider version during preflight before runtime claims.

## 4. Give the shell the shared contract

Use a short operator instruction that points at repository contracts instead of duplicating experiment semantics:

```text
Operate this Cusimanse project from the primary-agent shell.
Load recipes/agents/primary-agent.yaml and recipes/agents/primary-shell.yaml.
Load the selected adapter recipe and the project experiment contract.
Follow Discover → Validate → Preflight → Plan → Review → Approve → Provision →
Instrument → Execute → Collect → Reduce → Forensics → Independent verification →
Report → Preserve → Destroy.
Do not bypass policy, VM/OS controls, credentials, approvals or evidence integrity.
For privileged/destructive actions request approval before execution.
Do not claim PASS without runtime evidence and independent verification.
```

## 5. Non-destructive shell test

Before a VM run, ask the primary shell to:

```text
Load the Cusimanse primary-agent contract and selected adapter recipe.
Report the selected adapter, contract paths, required approval gates, security boundary,
and expected evidence outputs. Do not modify the host, VM, credentials or repository.
```

Expected: the agent identifies the selected adapter, YAML contract and security boundary without performing privileged actions.

## 6. Reference experiment: go-install-001

The primary shell should load:

```text
experiments/go-install-001/experiment.yaml
experiments/go-install-001/lima.yaml
experiments/go-install-001/run.sh
```

Then execute the semantic lifecycle from the primary-agent contract. Do not manually substitute a second orchestrator.

The experiment must produce auditable runtime evidence, an evidence index, findings and a report. Preserve/hash evidence before destroying the VM.

## 7. Adapter-specific shell starts

### Grok Build

```bash
grok --version
grok
```

If the installed release exposes a different command or mode, follow its provider documentation and keep the Cusimanse contract unchanged.

### Antigravity

```bash
agy
```

Load the shared contract and use the adapter's supported prompt/agent mode. Do not assume IDE actions are the security boundary.

### Pi

```bash
pi
```

For a non-interactive smoke invocation where supported:

```bash
pi -p 'Run the non-destructive Cusimanse primary-agent contract check.'
```

### Hermes

```bash
hermes
```

Use the installed Hermes version's supported prompt mode; the adapter contract records `hermes -z` as the intended one-shot form.

### Prime Intellect / Prime Agent

```bash
prime-agent
```

Use the provider-supported prompt mode and treat self-improvement as evidence-bounded: checkpoint → compare → propose → validate → human approve → promote.

### Codex

```bash
codex
```

Load the shared contract and keep execution scoped to approved actions and the disposable VM.

## 8. Runtime acceptance checklist

A run is `PASS` only when all are true:

- primary shell was the operator for the lifecycle
- contract and adapter recipe loaded
- preflight passed
- approvals were recorded for privileged/destructive actions
- VM/OS controls enforced the boundary
- instrumentation started before workload execution
- raw evidence was collected
- findings were independently verified
- evidence was hashed/preserved before destruction
- final report and audit records exist
- run is reproducible from its recorded inputs

Otherwise use `PARTIAL`, `FAIL` or `NOT_DEPLOYED` as defined by the acceptance contract.
