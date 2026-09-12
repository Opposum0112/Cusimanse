# 🦝 Cusimanse

<p align="center">
  <img src="docs/images/cusimanse-mascot.svg" alt="Cusimanse mascot — curious cyber raccoon for security research" width="1000">
</p>

> **Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.**

[![CI](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml/badge.svg)](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml)

Cusimanse is an **agent-neutral security research platform**. The primary operator is a replaceable adapter selected at bootstrap; experiment semantics live in YAML contracts and recipes, while VM/OS controls remain the security boundary.

## Primary operator model

The reference operator is Goose, but it is **not an architectural dependency**. Cusimanse can select a different operator when its adapter satisfies the common primary-agent contract.

```text
YAML contracts → Primary operator → policy/approval → Lima/QEMU VM
       ↑                 ↓                         ↓
  recipes/agents     orchestrate/execute       telemetry/evidence
       ↑                 ↓                         ↓
 learning proposals ← verify/report ← preserve → destroy
```

The operator owns planning, orchestration, approved execution, observation, evidence collection, reporting and lifecycle coordination. It does **not** own VM isolation, host credentials, privilege grants, policy bypass or final evidence verification.

### Adapter matrix

| Operator | Role | Status | Best fit |
|---|---|---|---|
| Goose | operator/executor | reference | current stable adapter |
| OpenCode | operator/executor | candidate | programmable CLI workflow |
| Grok Build | operator/orchestrator | candidate | provider-managed agent workflow |
| Antigravity | operator/orchestrator | candidate | interactive/provider workflow |
| Pi | operator/executor | candidate | minimal custom autonomous loop |
| Hermes | operator/executor | candidate | self-improving research operator |
| Codex | operator/executor | candidate | coding/CLI-oriented execution |
| Prime Intellect | self-improving operator | candidate | research/self-improvement experiments |
| Claude Code | enterprise operator | candidate | enterprise-controlled workflows |
| Devin | enterprise operator | candidate | provider-managed enterprise workflows |

`candidate` means the adapter contract exists; it is not a claim of provider E2E success. Runtime availability, credentials and smoke tests must pass before an adapter becomes `PASS`.

## Evidence-bounded self-learning

A primary operator may learn from verified runs, but learning is deliberately constrained:

`observe → compare → propose → validate → independently verify → human approve → promote`

Allowed promotion includes non-security recipe defaults, adapter command templates, routing hints and evidence-reduction heuristics. Learning cannot change VM isolation, credentials, privileges, network allowlists, approval requirements or evidence-integrity rules. See `recipes/agents/learning-loop.yaml` and `docs/agent-and-adapter-strategy.md`.

## Selecting and running a primary operator

### 1. Interactive selection

On a supported host:

```bash
./scripts/prerequisites.sh
```

Choose one operator when prompted. For automation:

```bash
CUSIMANSE_PRIMARY_ADAPTER=pi ./scripts/prerequisites.sh
```

The bootstrap records the selection in `.cusimanse/primary-agent.yaml`, installs only adapters with a verified installer, and runs selected-adapter preflight. Provider/manual-managed candidates are reported as `NOT_DEPLOYED` rather than using an unverified installer. The prerequisite script also prepares executable project scripts and user-local PATH handling.

### 2. Common preflight

```bash
./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

Preflight checks adapter availability/configuration, contract loading, YAML recipes, policy, audit/evidence paths and a non-destructive smoke test. Never put provider secrets in the repository.

### 3. Common execution contract

All adapters should execute the same semantic flow:

```text
Discover → Validate → Preflight → Plan → Review → Approve
→ Provision → Instrument → Execute → Collect → Reduce
→ Forensics → Independent verification → Report → Preserve → Destroy
```

### Grok Build

Select `grok-build` in prerequisites, complete provider authentication/configuration, then run the adapter using the common YAML project contract. The adapter should translate the contract into provider-native actions without changing experiment semantics. Start with a non-destructive smoke test, then run an approved reference experiment. If provider access is unavailable, record `NOT_DEPLOYED`.

### Antigravity

Select `antigravity`, complete its local/provider configuration, run `./scripts/agent-preflight.sh`, and load the common YAML project contract. Use Antigravity only through the adapter boundary; approvals, VM controls, audit and evidence preservation remain mandatory. Begin with a smoke test before a workload run.

### Pi

Select `pi` (or set `CUSIMANSE_PRIMARY_ADAPTER=pi`). Install/configure Pi, run preflight, then invoke the Pi adapter with the project recipe. Pi is particularly suitable for a small custom control loop because its harness can remain thin while Cusimanse supplies the lifecycle contract and safety gates.

### Hermes

Select `hermes`, install/configure Hermes using its supported distribution, run preflight, and execute the common project contract through the Hermes adapter. Hermes can be evaluated for self-improvement, but only evidence-bounded learning proposals may be promoted.

### Prime Intellect

Select `prime-intellect`, configure the provider/research agent, run preflight and then execute the common project contract. Treat self-improvement as an experiment: capture checkpoints, compare verified runs and require human approval before promoting changes.

### Codex

Select `codex`, configure the Codex CLI/provider, run preflight, and execute the common YAML contract through the Codex adapter. Codex should receive only the scoped tools/actions declared by the adapter and policy; it must not receive unrestricted host credentials or mounts.

### Enterprise: Claude Code / Devin

Select the enterprise adapter only when its provider integration and organizational controls are available. Configure identity, audit and approval controls outside git, run preflight, and execute the same YAML contract. Enterprise adapters should add stronger identity/audit integration rather than weaken the Cusimanse boundary.

## CrewAI evaluation

A **role-based CrewAI model is a strong fit for the inner research team, but not ideal as the security boundary or necessarily as the single primary operator**.

Recommended pattern:

```text
Primary operator
      │
      ▼
CrewAI research crew
 ├─ Planner
 ├─ Threat Modeler
 ├─ Static Analyst
 ├─ Runtime Analyst
 ├─ Network Analyst
 ├─ Malware/RE Analyst
 ├─ Detection Engineer
 ├─ Forensics Analyst
 ├─ Independent Verifier
 └─ Reporter
      │
      ▼
shared evidence / blackboard / audit
```

The primary operator should retain lifecycle authority and enforce the common contract. CrewAI can provide role specialization and parallel analysis, with every privileged action going back through the primary adapter and Cusimanse approval/policy controls. This gives better separation of duties than making a role-based crew the sandbox controller.

## Implementation roadmap for replacing Goose

1. Select an adapter through prerequisites.
2. Verify adapter binary/API and provider configuration.
3. Validate the common `recipes/agents/primary-agent.yaml` contract.
4. Verify recipe, policy, audit and evidence paths.
5. Run an adapter smoke test with no workload side effects.
6. Execute `go-install-001` under the selected adapter.
7. Compare audit/evidence/output against the Goose reference run.
8. Replay the experiment to test deterministic semantics.
9. Enable evidence-bounded learning and collect proposals.
10. Independently verify proposed improvements.
11. Human-review and promote only non-security changes.
12. Keep Goose available as a reference adapter until equivalence evidence is established.

## Testing status

CI validates repository structure, shell syntax, ShellCheck, Go formatting/vet, policy tests and recipe validation. Provider credentials, installed agent runtimes and disposable VM execution are environment-dependent. Therefore an adapter is not `PASS` from configuration alone.

Acceptance states:

- `PASS` — runtime behavior demonstrated with preserved evidence.
- `PARTIAL` — integration works but coverage/evidence is incomplete.
- `FAIL` — tested behavior violates the contract.
- `NOT_DEPLOYED` — unavailable, unconfigured or intentionally disabled.

## Security boundary

AI agents, prompts, skills, MCP servers, CrewAI and `policyctl` are **not** security boundaries. Enforcement comes from disposable VM/OS controls, filesystem/mount controls, credential separation, network controls and approval gates.

Untrusted workloads should run in disposable Lima/QEMU VMs. Preserve and hash evidence before VM destruction. Important findings require independent verification. Use only systems and workloads you are authorized to test.

## Recipes and contracts

- `recipes/agents/primary-agent.yaml` — replaceable primary-operator contract
- `recipes/agents/learning-loop.yaml` — evidence-bounded learning contract
- `recipes/adapters/` — provider/agent adapter contracts
- `recipes/orchestration/` — orchestration strategies
- `recipes/mcp/` — MCP contracts and registry
- `recipes/skills/` — skills registry
- `recipes/reference/` — frameworks, tools and research references
- `recipes/detection/` — detection validation
- `recipes/experiments/` — reference experiments

See `docs/agent-and-adapter-strategy.md` for architecture, implementation phases and adapter requirements.

## Existing platform documentation

- `01-deployment-architecture.md` — deployment architecture
- `03-deployment-runbook.md` — deployment/runbook
- `04-security-model.md` — security model
- `05-multi-agent-operating-model.md` — multi-agent operation
- `06-observability-and-evidence.md` — observability and evidence
- `07-experiment-framework.md` — experiment framework
- `10-validation-and-acceptance.md` — validation and acceptance
- `AGENTS.md` — agent/adapter operating instructions
- `SECURITY.md` — security boundaries and reporting

## License

**MIT License — Copyright (c) 2026 Opposum0112.** See `LICENSE`.
