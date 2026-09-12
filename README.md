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

Supported choices include `goose`, `opencode`, `grok-build`, `antigravity`, `pi`, `hermes`, `codex`, `prime-intellect`, `claude-code` and `devin`. The bootstrap records the selection in `.cusimanse/primary-agent.yaml`, installs only adapters with a verified installer, and runs selected-adapter preflight. Provider/manual-managed candidates are reported as `NOT_DEPLOYED` rather than using an unverified installer.

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

### Operator-specific implementation and run steps

The following steps describe the intended adapter path. Provider authentication and exact CLI/API invocation remain adapter-specific and must be verified on the target host.

**Grok Build**
1. Select `grok-build` during prerequisites.
2. Configure the supported Grok/Build provider access outside git.
3. Run `./scripts/agent-preflight.sh` and confirm contract/recipe/policy checks.
4. Give the operator the common YAML project contract, not a rewritten experiment prompt.
5. Run the non-destructive adapter smoke test.
6. Execute the approved `go-install-001` experiment.
7. Compare audit, evidence and findings with the Goose reference.

**Antigravity**
1. Select `antigravity`.
2. Configure its supported local/provider runtime outside git.
3. Run agent preflight and project validation.
4. Load the common YAML contract through the adapter.
5. Perform the smoke test before VM execution.
6. Execute only approved VM actions and preserve evidence before destroy.

**Pi**
1. Select `pi`; the prerequisites script can install Pi when its verified installer is available.
2. Configure the model/provider outside git.
3. Run preflight and load `recipes/agents/primary-agent.yaml`.
4. Use Pi as the thin control loop and Cusimanse as the lifecycle/safety contract.
5. Run `go-install-001`, preserve evidence and compare the result with the reference run.

**Hermes**
1. Select `hermes`.
2. Install/configure Hermes using its supported distribution; the bootstrap deliberately does not run an unverified installer.
3. Run `./scripts/agent-preflight.sh`.
4. Load the common YAML project contract through `recipes/adapters/hermes.yaml`.
5. Run the non-destructive smoke test, then an approved reference experiment.
6. Enable evidence-bounded learning only after verified runs exist.

**Prime Intellect**
1. Select `prime-intellect`.
2. Configure the supported Prime Intellect/Prime Agent environment outside git.
3. Run preflight and verify the common contract.
4. Treat self-improvement as a controlled experiment with checkpoints and replay.
5. Execute the reference experiment and independently verify outputs.
6. Promote only reviewed, non-security learning proposals.

**Codex**
1. Select `codex`; prerequisites can install the CLI when the verified npm path is available.
2. Configure the provider outside git.
3. Run preflight and project validation.
4. Pass the common YAML contract to the Codex adapter.
5. Scope tools/actions to the declared adapter and policy; never expose unrestricted host credentials or mounts.
6. Run the reference experiment and compare evidence with the Goose baseline.

**OpenCode**
1. Select `opencode` and install/configure the supported CLI.
2. Run preflight and validate the common contract.
3. Use the OpenCode adapter to translate the YAML contract into approved actions.
4. Smoke-test, execute `go-install-001`, preserve evidence and compare against the reference.

**Goose reference**
1. Select `goose`.
2. Configure its provider outside git.
3. Run preflight.
4. Execute the existing Goose project recipe as the baseline for adapter-equivalence testing.

**Claude Code / Devin**
1. Select the enterprise adapter.
2. Configure enterprise identity, provider access, audit and approval controls outside git.
3. Run preflight without exposing secrets.
4. Execute the same YAML contract through the enterprise adapter.
5. Validate that enterprise integrations strengthen identity/audit controls without bypassing VM/OS enforcement.

### Replacing Goose safely

Do not switch the project by merely changing a model name. The selected operator must first pass adapter-equivalence testing:

`contract load → recipe load → policy check → smoke test → VM experiment → evidence preservation → independent verification → report`

Keep Goose as a reference until the selected operator produces equivalent experiment semantics and acceptable evidence/audit output.

## CrewAI evaluation

A **role-based CrewAI model is a strong fit for the research-analysis layer**, especially where several specialist roles can work independently. It is less suitable as the sole security controller.

Recommended architecture:

```text
Selected primary operator
          │
          ▼
     CrewAI research crew
  ┌───────┼────────┐
Planner  Analysts  Verifier
  │        │          │
  └────────┼──────────┘
           ▼
     evidence/blackboard
           │
           ▼
      Reporter
```

The primary operator should retain lifecycle authority. CrewAI can coordinate Planner, Static Analyst, Runtime Analyst, Network Analyst, Malware/RE Analyst, Detection Engineer, Forensics Analyst, Independent Verifier and Reporter roles. Privileged operations must return through the primary adapter and Cusimanse approval/policy controls. This is preferable to putting the VM boundary inside a role-based framework.

## Implementation roadmap

1. Select one primary adapter.
2. Verify its runtime/provider configuration.
3. Validate `recipes/agents/primary-agent.yaml`.
4. Verify recipes, policy, audit and evidence paths.
5. Run a non-destructive smoke test.
6. Execute `go-install-001`.
7. Compare results with Goose.
8. Replay for adapter equivalence.
9. Enable evidence-bounded learning.
10. Validate and independently verify learning proposals.
11. Human-review and promote only non-security changes.
12. Keep rollback metadata and Goose as the reference until equivalence is demonstrated.

## Testing status

CI validates repository structure, shell syntax, ShellCheck, Go formatting/vet, policy tests and recipe validation. Provider credentials, installed agent runtimes and disposable VM execution are environment-dependent. Therefore an adapter is not `PASS` from configuration alone.

Acceptance states: `PASS` = runtime evidence; `PARTIAL` = incomplete coverage; `FAIL` = contract violation; `NOT_DEPLOYED` = unavailable/unconfigured/disabled.

## Security boundary

AI agents, prompts, skills, MCP servers, CrewAI and `policyctl` are **not** security boundaries. Enforcement comes from disposable VM/OS controls, filesystem/mount controls, credential separation, network controls and approval gates.

Untrusted workloads should run in disposable Lima/QEMU VMs. Preserve and hash evidence before VM destruction. Important findings require independent verification. Use only systems and workloads you are authorized to test.

## Recipes and contracts

- `recipes/agents/primary-agent.yaml` — replaceable primary-operator contract
- `recipes/agents/learning-loop.yaml` — evidence-bounded learning contract
- `recipes/adapters/` — provider/agent adapter contracts, including Hermes
- `recipes/orchestration/` — orchestration strategies
- `recipes/mcp/` — MCP contracts and registry
- `recipes/skills/` — skills registry
- `recipes/reference/` — frameworks, tools and research references
- `recipes/detection/` — detection validation
- `recipes/experiments/` — reference experiments

See `docs/agent-and-adapter-strategy.md` for architecture, implementation phases and adapter requirements.

## Documentation

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
