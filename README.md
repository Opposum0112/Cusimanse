# Cusimanse

> **An autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.**

Cusimanse is named after the hyper-curious mongoose that obsessively flips over every leaf and stone to uncover hidden details. The platform applies the same curiosity to software workloads: provision an isolated environment, observe execution, collect evidence, analyze behavior and preserve artifacts for independent verification.

## What Cusimanse does

```text
Experiment contract
       ↓
Agent adapter
(Goose / OpenCode / Grok Build / Antigravity)
       ↓
recipes + MCP + skills + policy
       ↓
plan → review → approval
       ↓
disposable Lima / QEMU VM
       ↓
instrument → execute → collect
       ↓
blackboard + evidence + telemetry
       ↓
reduce → forensics → verify
       ↓
report → preserve → destroy
```

The platform is **agent-neutral**. Goose is the current reference adapter, not the project identity. Adapter-specific prompts, tool wiring and integration details stay at the adapter boundary; experiment semantics remain shared.

## Security boundary

AI agents, prompts, skills, MCP servers and `policyctl` are **not** security boundaries. Enforcement comes from the VM/OS boundary, filesystem and mount controls, credential separation, network controls and explicit approval gates.

Key invariants:

- Untrusted workloads run in disposable VMs.
- Host credentials and unrestricted host mounts are denied.
- Privileged and destructive operations require approval.
- Public MCP/gateway exposure is denied by default.
- Instrumentation starts before the target workload.
- Evidence is preserved and hashed before VM destruction.
- Important findings require independent verification.
- Missing integrations are reported as `NOT_DEPLOYED`, never silently substituted.
- AI assertions are never treated as evidence.

See [`04-security-model.md`](04-security-model.md) and [`SECURITY.md`](SECURITY.md).

## Quick start

### 1. Install prerequisites

```bash
./scripts/prerequisites.sh
```

The bootstrap detects OS, distribution and architecture and installs only missing supported prerequisites. It verifies Git, Bash, Python 3, Ruby, Go, QEMU, Lima and Goose and ends with `Prerequisite PASS` when successful.

### 2. Load the environment

```bash
source ./scripts/goose-env.sh
```

This configures project paths only. **Never place API keys, cloud credentials or secrets in the repository.**

### 3. Validate

```bash
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

### 4. Bootstrap the project

```bash
goose run --recipe recipes/install/project-bootstrap.yaml
```

### 5. Run the reference experiment

```bash
goose run \
  --recipe recipes/goose/project.yaml \
  --params experiment=go-install-001 \
  --params section=project
```

The lifecycle is:

```text
Discover → Validate → Preflight → Install → Plan → Review → Approve
→ Provision → Instrument → Execute → Collect → Reduce → Forensics
→ Independent verification → Report → Preserve → Destroy
```

## Recipes and composition

Recipes are intentionally small and composable. Do not turn the project recipe into a monolith.

| Concern | Recipe family |
|---|---|
| Experiments | `recipes/experiments/` |
| Workloads | `recipes/workloads/` |
| Routing | `recipes/routing/` |
| Installation | `recipes/install/` |
| Host profile | `recipes/host/` |
| VM profile | `recipes/lima/` |
| Tools | `recipes/tools/` |
| Instrumentation | `recipes/instrumentation/` |
| Agent monitoring | `recipes/agent-monitoring/` |
| Agent roles | `recipes/agents/` |
| Orchestration/stages | `recipes/orchestration/`, `recipes/stages/` |
| Reporting | `recipes/reporting/` |
| MCP | `recipes/mcp/` |
| Skills | `recipes/skills/` |
| Audit | `recipes/audit/` |

`recipes/goose/project.yaml` is the reference Goose adapter composition. Other adapters must consume the same project contracts.

## Agent adapters

**Goose** — current reference operator/executor.

**OpenCode** — documented adapter target using `AGENTS.md`, shared recipes, registry-approved tools and the same evidence/audit lifecycle.

**Grok Build** — documented adapter target; Grok-specific wiring remains outside shared experiment semantics.

**Antigravity** — documented adapter target using the canonical `.agents/` roles/skills and MCP registry.

An adapter must not bypass policy, suppress audit, expose credentials, alter experiment semantics or claim `PASS` without evidence.

## Observation and evidence

Cusimanse treats runtime artifacts as the source of truth. Typical run output is:

```text
runs/<run-id>/
├── blackboard/
├── evidence/
├── telemetry/
├── audit/
├── reductions/
├── forensics/
├── verification/
├── reports/
└── manifest.json
```

The blackboard is coordination metadata, not evidence. Large raw evidence should be deterministically reduced before LLM analysis where practical while retaining the original artifacts.

Optional monitoring integrations include OpenTelemetry, Phoenix, Numbat and ADR. These provide observability/detection capabilities, not isolation boundaries.

## `policyctl`

`policyctl` is deliberately narrow: host/security policy configuration and the local token-usage dashboard. It is **not** the experiment controller, sandbox or agent harness.

```bash
./policyctl show
./policyctl validate
./policyctl check --action credentials
./policyctl check --action mounts
./policyctl check --action host-root
./policyctl check --action sudo
./policyctl check --action vm
./policyctl check --action network
./policyctl check --action git-write
./policyctl check --action push
./policyctl token-dashboard
```

A policy decision is not enforcement by itself; the adapter must honor it and host/VM controls enforce it.

## Validation and CI

Local validation includes recipe YAML parsing, shell syntax, architecture checks, Go formatting, `go vet`, unit tests, build checks and policy checks. Optional Python tests run when test modules are present.

GitHub Actions validates pushes and pull requests with least-privilege read permissions, concurrency cancellation, pinned action revisions, shell checks and Go checks. Dependency update automation covers Go modules and GitHub Actions.

Do not describe a capability as `PASS` unless it was actually exercised with evidence.

## Acceptance states

| State | Meaning |
|---|---|
| `PASS` | Runtime behavior demonstrated with evidence |
| `PARTIAL` | Capability worked but coverage/evidence is incomplete |
| `FAIL` | Tested behavior did not meet the contract |
| `NOT_DEPLOYED` | Capability unavailable or intentionally disabled |

Configuration is not evidence. AI output is not evidence.

## Responsible use

Use Cusimanse only against systems, software and workloads you own or are explicitly authorized to test. Untrusted workloads should run in disposable Lima/QEMU VMs. Never give an agent unrestricted host access or credentials merely because a prompt requests them.

AI-generated plans, commands, code and findings can be wrong, incomplete, stale or unsafe. Human researchers remain responsible for authorization, scope, approvals, safety and final interpretation.

## Documentation

- `01-deployment-architecture.md` — deployment architecture
- `02-system-requirements.md` — requirements
- `03-deployment-runbook.md` — deployment/runbook
- `04-security-model.md` — security model
- `05-multi-agent-operating-model.md` — multi-agent operation
- `06-observability-and-evidence.md` — observability and evidence
- `07-experiment-framework.md` — experiment framework
- `08-go-install-001.md` — reference experiment
- `09-operations-and-maintenance.md` — operations
- `10-validation-and-acceptance.md` — validation and acceptance
- `11-current-antigravity-reference.md` — Antigravity reference
- `AGENTS.md` — agent/adapter operating instructions
- `AI-DISCLAIMER.md` — AI limitations and responsible use
- `CONTRIBUTING.md` — contribution workflow
- `SECURITY.md` — security reporting and boundaries
- `RELEASE.md` — release process

## License

**MIT License — Copyright (c) 2026 Opposum0112.** See [`LICENSE`](LICENSE) for the authoritative license and [`NOTICE`](NOTICE) for the responsible-use and third-party software notice.
