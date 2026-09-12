# Agent-shell runtime runbook

Cusimanse is terminal-first. After bootstrap, the **selected primary agent shell is the operator**: it loads YAML contracts, plans, requests approval, orchestrates the VM lifecycle, executes approved workload actions, observes telemetry, collects evidence, invokes independent verification, reports, preserves evidence and destroys the disposable VM.

Host scripts are intentionally limited to prerequisite installation, configuration, validation and preflight. They are not a second orchestration controller.

## 0. Enter the repository

```bash
git clone <REPOSITORY_URL> Cusimanse
cd Cusimanse
git checkout agent-and-adapter
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

Do not translate Goose syntax to another agent. Use the selected adapter's native shell.

| Adapter | Interactive | Headless / run | Notes |
|---|---|---|---|
| Goose | `goose` | `goose run --text '<PROMPT>'` | reference |
| OpenCode | `opencode` | `opencode run '<PROMPT>'` | native non-interactive mode |
| Grok Build | `grok` | `grok -p '<PROMPT>'` | native headless mode |
| Antigravity | `agy` | `agy -p '<PROMPT>'` | verify installed CLI with `agy --help` |
| Pi | `pi` | `pi -p '<PROMPT>'` | native print mode |
| Hermes | `hermes` | TUI-first | use the installed Hermes CLI's supported interactive prompt flow |
| Prime Agent | `prime-agent` | `prime-agent -p '<PROMPT>'` | native print mode |
| Codex | `codex` | verify installed CLI with `codex --help` | version-specific non-interactive syntax |

Grok's current documentation explicitly supports `grok -p` for headless scripting; OpenCode documents `opencode run`; Prime Agent documents `prime-agent -p`. citeturn1search0turn1search1turn0search1

## 4. Give the primary shell the shared contract

Start the selected shell, then provide this operator instruction:

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

Before provisioning a VM, ask the primary shell:

```text
Load the Cusimanse primary-agent contract and selected adapter recipe.
Report the selected adapter, contract paths, required approval gates, security boundary,
and expected evidence outputs. Do not modify the host, VM, credentials or repository.
```

Expected result: the agent identifies the selected adapter, YAML contract, approval gates, evidence paths and VM/OS security boundary without privileged or destructive action.

## 6. Reference experiment: go-install-001

The primary shell should load:

```text
experiments/go-install-001/experiment.yaml
experiments/go-install-001/lima.yaml
experiments/go-install-001/run.sh
```

Then execute the semantic lifecycle from the primary-agent contract. The primary shell may call declared repository scripts, but no second orchestrator should take ownership of the lifecycle.

Required outputs:

- runtime audit records;
- raw evidence and evidence index;
- findings/report;
- independent verification result;
- preservation/hash manifest before VM destruction.

## 7. Adapter-specific smoke tests

### Grok Build

```bash
grok --version
grok inspect
grok -p 'Load recipes/agents/primary-agent.yaml and perform the non-destructive shell test. Do not modify anything.'
```

For CI/headless use, prefer structured output where required:

```bash
grok -p 'Perform the non-destructive Cusimanse shell test.' --output-format json
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

Hermes is TUI-first. Use its native interactive prompt flow to load the contract; do not rely on an undocumented one-shot flag. citeturn877file0L2-L2

### Prime Agent

```bash
prime-agent --help
prime-agent -p 'Load the Cusimanse primary-agent contract. Perform only the non-destructive shell test.'
```

Prime Agent's current CLI documents `-p/--print` and supports piped stdin. Its model-generated commands execute with user permissions, so the external VM/OS boundary remains mandatory. citeturn0search1

### Codex

```bash
codex --help
codex
```

Use the installed version's documented non-interactive mode after confirming it with `codex --help`.

## 8. Runtime acceptance

A run is `PASS` only when all are true:

- the selected primary shell owned the lifecycle;
- the contract and adapter recipe loaded;
- preflight passed;
- approvals were recorded for privileged/destructive actions;
- VM/OS controls enforced the boundary;
- instrumentation started before workload execution;
- raw evidence was collected;
- important findings were independently verified;
- evidence was hashed/preserved before destruction;
- final report and audit records exist;
- the run is reproducible from recorded inputs.

Otherwise use `PARTIAL`, `FAIL` or `NOT_DEPLOYED` according to the acceptance contract.
