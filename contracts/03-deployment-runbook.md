# 03 — Deployment Runbook

![Experiment workflow](../docs/images/cusimanse-workflow.png)

## Runtime model

Cusimanse is **terminal-first and purely primary-agent-shell driven at runtime**. Exactly one selected primary agent owns the complete operator, execution and orchestration lifecycle. Host scripts only bootstrap, install prerequisites, select/configure the adapter, validate and preflight.

The security boundary is disposable Lima/QEMU compute plus VM/OS controls. Agents, skills, MCP, CrewAI and `policyctl` are not containment mechanisms.

For the most granular provider-specific procedure, use `docs/agent-shell-runbook.md`.

## 1. Bootstrap

```bash
./scripts/prerequisites.sh
```

Choose exactly one primary interactively, or select explicitly:

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

Selection is written to `.cusimanse/primary-agent.yaml`. Provider/manual candidates remain `NOT_DEPLOYED` until configured and exercised.

## 2. Preflight and repository validation

```bash
./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

Then verify the selected native shell:

```bash
cat .cusimanse/primary-agent.yaml
command -v <PRIMARY_COMMAND>
<PRIMARY_COMMAND> --help
```

## 3. Start the selected primary shell

| Adapter | Interactive shell | Native run form |
|---|---|---|
| Goose | `goose` | `goose run --text '<PROMPT>'` |
| OpenCode | `opencode` | `opencode run '<PROMPT>'` |
| Grok Build | `grok` | `grok -p '<PROMPT>'` |
| Antigravity | `agy` | verify with `agy --help` |
| Pi | `pi` | `pi -p '<PROMPT>'` |
| Hermes | `hermes` | TUI-first; use native interactive flow |
| Prime Agent | `prime-agent` | `prime-agent -p '<PROMPT>'` |
| Codex | `codex` | verify with `codex --help` |

Never assume that a Goose command or flag works in another shell.

## 4. Give the shell the Cusimanse contract

```text
Operate this Cusimanse repository as the selected primary agent shell.
Load recipes/agents/primary-agent.yaml and recipes/agents/primary-shell.yaml.
Load the selected adapter recipe and the experiment YAML.
Execute the complete lifecycle: Discover → Validate → Preflight → Plan → Review
→ Approve → Provision → Instrument → Execute → Collect → Reduce → Forensics
→ Independent verification → Report → Preserve → Destroy.
Do not bypass policy, approvals, credentials, VM/OS controls or evidence integrity.
Do not claim PASS without runtime evidence and independent verification.
```

## 5. Non-destructive smoke test

Before provisioning compute:

```text
Load the Cusimanse contracts and selected adapter recipe.
Report the selected adapter, contract paths, approval gates, security boundary,
and expected evidence outputs.
Do not modify the host, compute environment, credentials or repository.
```

Expected: contract discovery only, with no privileged/destructive operation.

## 6. Reference experiment

Use `experiments/go-install-001` for adapter equivalence. The primary shell should load:

```text
experiments/go-install-001/experiment.yaml
experiments/go-install-001/lima.yaml
experiments/go-install-001/run.sh
```

The primary shell remains responsible for the lifecycle while calling only declared scripts/tools as needed.

## 7. Runtime evidence checks

After the run:

```bash
find evidence blackboard experiments/go-install-001 -maxdepth 3 -type f -print
```

A runtime `PASS` requires:

- selected primary shell owned the lifecycle;
- contract and adapter recipe loaded;
- preflight passed;
- approval records exist for privileged/destructive actions;
- VM/OS controls enforced isolation;
- instrumentation started before workload execution;
- raw evidence was collected;
- important findings were independently verified;
- evidence was hashed/preserved before destruction;
- report and audit records exist;
- recorded inputs permit replay.

## 8. Adapter-specific smoke commands

Use each installed release's `--help` output to confirm the documented invocation before runtime use. Never assume provider CLI flags are interchangeable.

## 9. Adapter equivalence

Run `go-install-001` with Goose and then with one candidate adapter. Compare semantic lifecycle, runtime telemetry, evidence, findings, audit records and independent verification. Textual similarity between agent responses is not equivalence.

## 10. Learning

Learning remains in the primary shell:

```text
verified run → compare → propose → validate/replay
→ independent verification → human approve → promote → rollback checkpoint
```

Only reviewed non-security improvements may be promoted. Security boundaries, credentials, privileges, network allowlists, approval requirements and evidence-integrity rules remain outside autonomous learning authority.

## 11. Token dashboard

`policyctl` provides local token accounting/observability:

```bash
./policyctl token-dashboard
```

It is not an authorization or containment layer.
