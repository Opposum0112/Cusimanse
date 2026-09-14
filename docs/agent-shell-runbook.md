# Agent-shell runtime runbook

Cusimanse is terminal-first. After bootstrap, the **selected primary agent shell is the operator**: it loads the authoritative YAML experiment recipe, plans, requests approval, orchestrates the VM lifecycle, executes approved workload actions, observes telemetry, collects evidence, invokes independent verification, reports, preserves evidence and destroys the disposable VM.

Goose is the **reference primary operator** in this branch. Other agents use the same contract/recipe model through their adapters; their runtime acceptance remains provider-specific.

Host scripts are intentionally limited to prerequisite installation, configuration, validation and preflight. They are not a second orchestration controller.

## 0. Enter the repository

```bash
git clone <REPOSITORY_URL> Cusimanse
cd Cusimanse
git checkout goose-refactor
```

## 1. Bootstrap and select exactly one primary

Use the single installation front door, then preflight:

```bash
./scripts/install.sh
./scripts/preflight.sh
./policyctl validate
```

The canonical adapter registry is `recipes/agents/adapter-matrix.yaml`. It requires exactly one primary shell. Goose is the reference operator; other adapters remain candidates until their provider-specific commands and end-to-end runtime behavior are validated.

The selection is recorded at `.cusimanse/primary-agent.yaml` when the bootstrap flow is used.

## 2. Validate before starting the agent

```bash
./scripts/tests/validate.sh
```

Confirm the selected command:

```bash
cat .cusimanse/primary-agent.yaml
command -v <PRIMARY_COMMAND>
<PRIMARY_COMMAND> --help
```

The last command is intentionally provider-specific: use it to confirm the CLI syntax installed on the target host before runtime acceptance.

## 3. Goose reference operator

For the reference Goose path, use the native Goose recipe adapter:

```bash
goose --help
goose
```

The native recipe is:

```text
recipes/goose/project.yaml
```

The Goose adapter accepts the experiment, contract and authoritative recipe as parameters. Use the installed Goose version's documented invocation syntax; the declared adapter form is:

```text
goose run --recipe recipes/goose/project.yaml \
  --params experiment=<EXPERIMENT> \
  --params contract=<CONTRACT> \
  --params recipe=<RECIPE>
```

The Goose recipe does not redefine the experiment. It tells Goose how to operate Cusimanse from the authoritative contract and YAML recipe.

## 4. Other primary-agent adapters

Do not translate one adapter's syntax into another. Use the selected adapter's native shell.

| Adapter | Interactive | Headless / run | Status |
|---|---|---|---|
| Goose | `goose` | native Goose recipe | reference |
| OpenCode | `opencode` | `opencode run '<PROMPT>'` | candidate |
| Grok Build | `grok` | `grok -p '<PROMPT>'` | candidate |
| Antigravity | `agy` | `agy -p '<PROMPT>'` | candidate; verify with `agy --help` |
| Pi | `pi` | `pi -p '<PROMPT>'` | candidate |
| Hermes | `hermes` | TUI-first | candidate; use native interactive flow |
| Prime Agent | `prime-agent` | `prime-agent -p '<PROMPT>'` | candidate |
| Codex | `codex` | version-specific; verify with `codex --help` | candidate |
| Claude Code | `claude` | `claude '<PROMPT>'` | enterprise candidate |
| Devin | provider-managed | provider-managed | enterprise candidate |

The adapter matrix is configuration, not proof of deployment. A CLI must pass host preflight and a disposable-VM end-to-end test before being considered runtime accepted.

## 5. Native primary-agent operating instruction

When using an interactive primary agent, provide the shared operator instruction:

```text
Operate this Cusimanse experiment as the primary lifecycle authority.
Load the Markdown contract, the authoritative YAML experiment recipe, the workload recipe,
recipes/agents/primary-agent.yaml and recipes/agents/primary-shell.yaml.
Resolve referenced profiles and registries before execution.
Use native multiagent/subagent delegation for declared specialist role recipes when useful.
Follow Discover → Validate → Preflight → Plan → Review → Approve → Provision →
Instrument → Execute → Collect → Reduce → Forensics → Independent verification →
Report → Preserve → Destroy.
Do not bypass policy, VM/OS controls, credentials, approvals or evidence integrity.
Do not create a competing lifecycle controller.
Do not claim PASS without runtime evidence and independent verification.
```

## 6. Non-destructive shell test

Before provisioning a VM, ask the primary shell:

```text
Load the Cusimanse primary-agent contract, primary-shell contract, adapter matrix,
authoritative experiment recipe and selected adapter recipe.
Report the selected adapter, contract paths, required approval gates, security boundary,
participating specialist roles, and expected evidence outputs. Do not modify the host,
VM, credentials or repository.
```

Expected result: the agent identifies the selected adapter, YAML contract, approval gates, evidence paths, specialist roles and VM/OS security boundary without privileged or destructive action.

## 7. Reference experiments

The reference cases are:

```text
experiments/go-install-001/
recipes/experiments/go-install-001.yaml

recipes/experiments/npm-install-001.yaml
```

The primary agent should discover the actual case files and referenced recipes rather than inventing configuration. The recipe remains authoritative.

For either experiment, the lifecycle is:

```text
Contract
  ↓
Authoritative Experiment Recipe
  ↓
Goose / selected Primary Agent
  ↓
Native specialist delegation
  ↓
Policy approval
  ↓
Disposable Lima/QEMU VM
  ↓
Instrumentation
  ↓
Workload
  ↓
Evidence / Blackboard
  ↓
Analysis / Forensics
  ↓
Independent Verification
  ↓
Research Report
  ↓
Preservation
  ↓
VM Destruction
  ↓
Optional Learning
```

## 8. Runtime acceptance

A run is `PASS` only when all are true:

- the selected primary shell owned the lifecycle;
- the contract and authoritative experiment recipe loaded;
- the selected adapter loaded and passed preflight;
- approvals were recorded for privileged/destructive actions;
- VM/OS controls enforced the boundary;
- instrumentation started before workload execution and ran against the workload inside the VM;
- raw evidence was collected and indexed;
- important findings were independently verified;
- evidence was hashed/preserved before destruction;
- final report and audit records exist;
- the run is reproducible from recorded inputs.

Otherwise use `PARTIAL`, `FAIL` or `NOT_DEPLOYED` according to the acceptance contract.

## 9. Researcher output

The primary output is:

```text
runs/<session-id>/research-report/report.md
```

with the preserved session artifact and evidence package under:

```text
runs/<session-id>/
```

The researcher should read the report first, then verification, analysis, evidence index and preservation/provenance records. Model output is not evidence.
