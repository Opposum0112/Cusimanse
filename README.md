# 🦝 Cusimanse

<p align="center">
  <img src="docs/images/cusimanse-mascot.svg" alt="Cusimanse mascot — curious cyber raccoon for security research" width="1000">
</p>

> **Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.**

[![CI](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml/badge.svg)](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml) [![Go](https://img.shields.io/badge/Go-1.23%2B-00ADD8?logo=go)](https://go.dev/) [![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash)](https://www.gnu.org/software/bash/) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![Release](https://img.shields.io/github/v/release/Opposum0112/Cusimanse?include_prereleases&label=release)](https://github.com/Opposum0112/Cusimanse/releases)

Cusimanse is named after the hyper-curious mongoose that obsessively flips over every leaf and stone to uncover hidden details. The platform applies the same curiosity to software workloads: provision an isolated environment, observe execution, collect evidence, analyze behavior and preserve artifacts for independent verification.

## About

Cusimanse is a **research and experimentation platform**, not a production malware sandbox. It combines disposable Lima/QEMU virtual machines with agent adapters, composable recipes, instrumentation, policy checks, evidence handling and optional observability integrations. The design keeps experiment semantics independent from the agent used to operate them.

**Status:** `v1.0.0-beta.1` — early beta. Strangers should treat the first successful outcome as **host install + lint**, not a proven VM sandbox.

## Limitations

Read this before cloning.

- **This is a beta research lab, not a product.** APIs, recipes and adapters can change. There is no claim of sandbox-escape resistance or production security certification.
- **Green CI is lint only.** GitHub Actions checks shell syntax, ShellCheck, `gofmt`, `go vet`, `policyctl` unit tests and file presence. It does **not** boot Lima, run `go-install-001`, or exercise MCP/skills.
- **The only implemented operator path is Goose.** OpenCode, Grok Build and Antigravity are documented targets (`NOT_DEPLOYED`) until an adapter directory gives a concrete command.
- **Skills and MCP registries are contracts.** Declared servers/skills are not a running MCP stack. Missing pieces must be reported as `NOT_DEPLOYED`.
- **You must configure Goose yourself.** Model provider and API keys live in your user environment. They must never be committed.
- **Host coverage is uneven.** `scripts/prerequisites.sh` targets common Linux distros and macOS with Homebrew. Unsupported distros fail closed. x86_64 is the tested baseline; arm64 is `PARTIAL` until you evidence it.
- **`jq` / `yq` / `ripgrep` / collectors are not installed by default.** Experiments select them. Absence is `NOT_DEPLOYED`, not a silent substitute.
- **`install.sh` does not start an experiment.** It only prepares the host and builds `./policyctl`.
- **Do not pass document numbers as Goose `section`.** Use `section=project` for the full reference run. `01`–`11` are Markdown chapters.
- **Do not publish credentials, private workload data, or unredacted evidence.**
- **Use only systems and software you are authorized to test.**

A stranger-ready test stops at step 3 below if Goose or a VM is not available. That is still a valid result.

## How to start

Tested intent: a Linux or macOS host with sudo/Homebrew, ~16 GB RAM, 50 GB+ free disk, and Git.

Clone (private repo: you need access), then work from the repository root.

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout main
```

### Step 1 — Host install (required)

```bash
./scripts/install.sh
```

Expect `Install PASS (host tools + policyctl)`.

This installs missing packages when the OS is supported (Git, Bash, Python 3, Go, QEMU, Lima, Goose CLI), writes `./policyctl`, and runs `policyctl validate`. It does **not** start Goose or a VM.

If this fails, stop. Fix the host (unsupported distro, missing sudo, no Homebrew on macOS, no `qemu-system-x86_64` on PATH). Do not continue to Goose.

### Step 2 — Environment (each new shell)

```bash
source ./scripts/goose-env.sh
```

This sets project paths only. No secrets.

### Step 3 — Lint / policy check (stranger-complete if you stop here)

```bash
bash ./scripts/tests/validate-project.sh
```

Expect `PASS project validation`.

This is the same class of check as CI. It is **not** evidence that a disposable VM experiment works.

### Step 4 — Goose config (you do this outside git)

1. Confirm `command -v goose` succeeds (step 1 should have installed the CLI if it was missing).
2. Configure Goose’s model/provider using Goose’s own docs.
3. Put any API key in your shell or Goose user config — **never in this repository.**

If you cannot configure a provider, stop. Record Goose as `NOT_DEPLOYED`. Steps 1–3 were still a successful stranger test of the install path.

### Step 5 — Bootstrap recipes (optional, needs Goose)

```bash
goose run --recipe recipes/install/project-bootstrap.yaml
```

### Step 6 — Reference experiment (optional, needs Goose + Lima/QEMU + approval)

```bash
goose run \
  --recipe recipes/goose/project.yaml \
  --params experiment=go-install-001 \
  --params section=project
```

Use `section=project` only. Privileged or VM actions should wait for human approval. Preserve and hash evidence before any VM destroy.

Lifecycle if the operator path works:

```text
Discover → Validate → Preflight → Install → Plan → Review → Approve
→ Provision → Instrument → Execute → Collect → Reduce → Forensics
→ Independent verification → Report → Preserve → Destroy
```

More detail: [`03-deployment-runbook.md`](03-deployment-runbook.md). Requirements: [`02-system-requirements.md`](02-system-requirements.md).

### What “worked” means

| You reached | Honest result |
|---|---|
| Step 3 `PASS project validation` | Host install + lint works. Publish-worthy as a **beta install path**. |
| Step 5 Goose recipe runs without inventing tools | Goose adapter can load contracts. |
| Step 6 leaves hashed evidence under `runs/<id>/` before VM destroy | Reference experiment exercised. Only then may that run be `PASS`. |

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

## Deployment architecture

The deployment model separates the **agent/operator plane** from the **VM/OS enforcement boundary**. Shared contracts define experiment semantics; adapters operate approved actions; disposable Lima/QEMU VMs contain the workload; instrumentation and evidence pipelines provide the basis for analysis and verification.

![Cusimanse deployment architecture](docs/images/cusimanse-deployment-architecture.svg)

**Control flow:** `Intent → Contract → Adapter → Policy/Approval → Disposable VM → Instrument → Execute → Collect → Verify → Preserve → Destroy`

For the detailed deployment layers, boundaries and lifecycle, see [`01-deployment-architecture.md`](01-deployment-architecture.md).

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

**OpenCode**, **Grok Build**, and **Antigravity** are documented adapter *targets*. They are `NOT_DEPLOYED` until an adapter directory documents a concrete command. Do not treat those names as installers.

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

Build it with `./scripts/install.sh` or `go build -o policyctl ./cmd/policyctl`. `policyctl` is deliberately narrow: host/security policy configuration and the local token-usage dashboard. It is **not** the experiment controller, sandbox or agent harness.

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

The release workflow packages the repository from an immutable version tag and publishes checksums with the GitHub release. Release artifacts are generated from Git history rather than from a developer working tree.

Do not describe a capability as `PASS` unless it was actually exercised with evidence.

## Contributing

Bug reports, documentation fixes, tests, recipes and adapter improvements are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request.

- **Bug:** use the bug-report issue template and include reproducible steps, environment details and relevant logs with secrets removed.
- **Security vulnerability:** do **not** open a public issue; follow [`SECURITY.md`](SECURITY.md).
- **Feature/change:** explain the experiment or operator contract being improved and include tests or validation evidence where practical.
- **Pull requests:** keep changes focused, preserve security invariants and wait for required CI checks.

## Reporting bugs and security issues

For ordinary defects, use GitHub Issues with the **Bug Report** template. For vulnerabilities involving credential exposure, host escape, unsafe mounts, privilege escalation, malicious workflow changes or other security-sensitive behavior, use the private reporting process described in [`SECURITY.md`](SECURITY.md).

Please never publish credentials, tokens, private keys, sensitive workload data or unredacted forensic artifacts in an issue or pull request.

## Beta release policy

`v1.0.0-beta.*` releases are pre-production research releases. They are intended for authorized, controlled environments and may contain incomplete integrations or breaking changes. A beta release is not a claim of production security certification, sandbox escape resistance or operational completeness.

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
