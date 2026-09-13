# Cusimanse research workflow

This is the canonical operator workflow for a research session. The researcher declares the experiment; the host shell prepares the environment; exactly one selected primary agent owns the agent-side lifecycle; specialist agents contribute through declared roles; evidence, audit, session state and reporting remain durable.

## 1. Create the experiment

1. Write the Markdown research contract under `contracts/` with intent, scope, hypothesis, safety, evidence requirements, acceptance criteria and review requirements.
2. Write the YAML experiment recipe under `recipes/experiments/` and reference the workload, host profile, compute profile, instrumentation, primary agent, roles, skills, MCP, orchestration, policy, routing, reporting and observability profiles.
3. Validate the recipe graph and contract before execution.
4. Create a session from `recipes/session/session-state.yaml` and record immutable experiment/contract/recipe references plus every selected profile.

The session state is the durable join key for the whole run: `runs/<session-id>/session.yaml`.

## 2. Prepare and install the host

The researcher uses the normal host shell. The front door is:

```bash
./scripts/cusimanse-host.sh
```

Then validate prerequisites and the selected host profile:

```bash
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
./scripts/tests/validate-project.sh
```

The host profile declares the tool recipe, so host tooling is installed/preflighted from configuration rather than becoming an ad-hoc second controller. Example profile: `recipes/host/research-host.yaml`; tool inventory: `recipes/tools/security-research.yaml`.

Host installation never silently starts the workload. Credentials are not passed to compute by default. Instrumentation for the target workload runs inside the disposable compute/VM boundary.

## 3. Select the primary agent adapter

Choose exactly one primary adapter and record it in session state:

| Adapter | Native interactive command | Prompt/run form |
|---|---|---|
| Goose | `goose` | `goose run --text '<PROMPT>'` |
| OpenCode | `opencode` | `opencode run '<PROMPT>'` |
| Grok Build | `grok` | `grok -p '<PROMPT>'` |
| Antigravity | `agy` | `agy -p '<PROMPT>'` |
| Pi | `pi` | `pi -p '<PROMPT>'` |
| Hermes | `hermes` | TUI-first interactive prompt |
| Prime Agent | `prime-agent` | `prime-agent -p '<PROMPT>'` |
| Codex | `codex` | verify version-specific non-interactive syntax |
| Claude Code | `claude` | `claude '<PROMPT>'` |
| Devin | provider-managed | provider-managed |

Use `recipes/agents/adapter-matrix.yaml` as the source of truth. A documented adapter is not runtime accepted until host preflight and an end-to-end disposable-compute test succeed.

## 4. Start the agent shell

After the normal host-shell preparation, start the selected primary agent using its native command. Do not manually execute each lifecycle stage as a separate human shell command. The agent is the operator for the research lifecycle.

Give it the experiment prompt below, substituting the actual session and experiment references:

```text
Operate session <SESSION_ID> for experiment <EXPERIMENT_ID>.
Load the research contract, experiment recipe, recipes/session/session-state.yaml,
recipes/agents/primary-agent.yaml, recipes/agents/primary-shell.yaml,
the selected adapter profile, host/compute/tool profiles, policy, routing,
observability, audit and reporting profiles.

First checkpoint session state and audit. Validate the complete recipe graph and
preflight the selected adapter. Report the selected adapter and all profile refs.
Plan the experiment and request human approval for privileged or destructive actions.

After approval, provision the declared disposable compute, start workload
instrumentation before execution, execute only the approved workload, collect raw
evidence and telemetry, hash and index evidence, update the blackboard, and run
forensics, analysis and independent verification.

Produce the research report and preservation manifest. Preserve evidence before
compute destruction. Update session.yaml and append audit events for requested,
approved, executed and observed actions.

At session end, finalize token accounting and refresh the session dashboard. The
session is COMPLETE only when required artifacts, audit, verification, preservation
and dashboard state exist. Otherwise use PARTIAL or FAILED and explain why.

Do not bypass policy, approvals, credentials controls or the compute/VM boundary.
Do not treat model output as evidence. Do not silently change the experiment contract.
Learning or skill improvements must remain candidates until replay, independent
verification and human approval are complete.
```

## 5. Primary-agent lifecycle

```text
Create session
  → Validate
  → Preflight
  → Plan
  → Review
  → Request approval
  → Provision compute
  → Start instrumentation
  → Execute workload
  → Collect evidence
  → Reduce evidence
  → Forensics
  → Analysis / specialist roles
  → Independent verification
  → Research report
  → Preserve + hash
  → Refresh token/session dashboard
  → Destroy compute
  → Finalize session state + audit
  → COMPLETE / PARTIAL / FAILED
```

The primary agent remains lifecycle authority. CrewAI, LangGraph, Taskflow and other orchestration tools can structure specialist work or stateful task execution, but they do not become a security boundary or a second lifecycle controller.

## 6. Specialist and learning flow

Specialist roles operate on declared inputs and write outputs/evidence references to the blackboard. A taskflow can decompose work; LangGraph can provide stateful graph/checkpoint execution; CrewAI can delegate specialist roles. Their outputs remain subject to the primary agent's policy and evidence rules.

Learning is explicitly evidence-bounded:

```text
retrieve prior cases/skills/evidence
        ↓
taskflow decomposition
        ↓
execute
        ↓
evaluate against contract
        ↓
refine candidate skill/recipe
        ↓
replay on distinct/frozen artifact
        ↓
independent verification
        ↓
human approval
        ↓
promote reviewed skill
        ↓
rollback if regression/safety issue
```

Base contracts and security boundaries are immutable during learning. No learned skill can grant privilege, change security policy, bypass approval, expose credentials or alter the VM boundary autonomously.

## 7. Artifact store and report

Each session owns one durable artifact tree:

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

The report must distinguish observed evidence from inference, cite artifact references, include versions and failed steps, and never claim an unverified security property.

## 8. Session completion and dashboard clearing

At the end of **every session**, the primary agent must:

1. stop/close runtime instrumentation cleanly;
2. preserve and hash raw evidence before destroying compute;
3. finalize audit and provenance manifests;
4. write the independent verification result and research report;
5. finalize token usage for the session;
6. refresh/write the session dashboard snapshot;
7. mark `session.yaml` `COMPLETE`, `PARTIAL` or `FAILED` with timestamps and artifact refs;
8. only then destroy disposable compute if preservation requirements are satisfied.

The aggregate dashboard may remain historical, but the active session view must be finalized/cleared so no prior session is presented as currently active.

## 9. Runtime acceptance

A session is `PASS` only when the selected primary agent actually owns the lifecycle, policy/approval records exist where required, the compute/VM boundary was exercised, instrumentation preceded execution, evidence was preserved and hashed, independent verification completed, the report and audit exist, and the session state is reproducible from recorded inputs.

Static configuration or a successful CLI `--help` check is never runtime PASS.
