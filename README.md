# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

[![Validation](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml/badge.svg?branch=goose-native)](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml)
[![Go](https://img.shields.io/badge/Go-1.22%2B-00ADD8?logo=go&logoColor=white)](https://go.dev/)
[![YAML](https://img.shields.io/badge/YAML-recipes-cb171e?logo=yaml&logoColor=white)](https://yaml.org/)
[![LinkML](https://img.shields.io/badge/LinkML-schema-0F766E?logo=databricks&logoColor=white)](https://linkml.io/)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-enabled-4EAA25?logo=gnu-bash&logoColor=white)](https://www.shellcheck.net/)
[![Goose](https://img.shields.io/badge/Goose-native%20operator-111827?logo=github&logoColor=white)](https://github.com/block/goose)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-025E8C?logo=dependabot&logoColor=white)](https://github.com/Opposum0112/Cusimanse/network/updates)
[![AI](https://img.shields.io/badge/AI-agentic%20security%20research-7C3AED)](https://github.com/Opposum0112/Cusimanse)
[![Beta](https://img.shields.io/badge/status-beta-F59E0B)](https://github.com/Opposum0112/Cusimanse)

> **Status: Beta — research framework for testers and researchers**
>
> Fork it, run the reference experiments, read the evidence, report bugs, and send pull requests. Expect recipes, schema fields and operator commands to evolve during beta.

> **AI use and responsible contribution.** Cusimanse uses AI-assisted development and agentic operators as part of its research workflow. AI output is not automatically authoritative, secure, correct or production-ready. Review, test and validate every change. Do not treat a model as the sole authority for authorization, evidence or safety-critical actions. Use the project only for authorized research, keep secrets out of Git and guests, and stay inside declared policy and disposable-compute bounds. See [AI-DISCLAIMER.md](AI-DISCLAIMER.md), [SECURITY.md](SECURITY.md), [CONTRIBUTING.md](CONTRIBUTING.md) and [LICENSE](LICENSE).

Cusimanse is a declarative, Goose-operated security-research lab on disposable compute. You declare a research question and requirements. Goose plans and orchestrates roles. The Go CLI (`cmd/cusimanse`) resolves profiles, evaluates policy and runs the fixed workload. Evidence is hashed, independently verified, written into a research report, then preserved before the guest is destroyed.

![Cusimanse layered architecture](docs/architecture/agentic-native-layers.svg)

## Table of contents

1. [What you are testing](#what-you-are-testing)
2. [Research outputs](#research-outputs)
3. [Repository structure](#repository-structure)
4. [Install and first check](#install-and-first-check)
5. [Access and observability](#access-and-observability)
6. [Researcher workflow (`npm-install-001`)](#researcher-workflow-npm-install-001)
7. [LinkML schema in the workflow](#linkml-schema-in-the-workflow)
8. [Validation and integration tests](#validation-and-integration-tests)
9. [Safety, license and contribution](#safety-license-and-contribution)

## What you are testing

| Layer | What it is | Who touches it |
|---|---|---|
| Schema-backed experiment | `experiments/<id>.yaml` validated by LinkML / JSON Schema | Researcher writes values only |
| Runtime requirements | `recipes/experiments/<id>.yaml` | Researcher + resolver |
| Goose recipes | `recipes/<id>/recipe.yaml`, `recipes/goose/session.yaml`, `recipes/subrecipes/` | Goose session |
| Host bootstrap | `host-prep/default.yaml` + `scripts/install.sh` | Normal shell first |
| Control plane | `cmd/cusimanse` | Goose *or* normal shell |
| Disposable guest | Lima/QEMU (Multipass fallback on Windows) | Runtime after `--approved` |
| Evidence and report | `runs/<session-id>/` | Verifier + reporter roles |

The agent decides what research to do. Cusimanse decides whether and how it may execute.

## Research outputs

Every approved run writes a session tree under `runs/<session-id>/`. Treat this directory as the research artifact bundle, not a scratch folder.

```text
runs/<session-id>/
├── session.yaml                         session identity, experiment, operator
├── evidence/
│   ├── workload.txt                     raw guest workload transcript
│   ├── process.txt / syscalls.txt / network.txt / filesystem.txt
│   ├── collector-hashes.txt
│   ├── index.yaml                       evidence inventory
│   └── audit/{events.jsonl,manifest.sha256}
├── provenance/manifest.sha256           hashes of preserved inputs + evidence
├── analysis/summary.md                  specialist interpretation (not raw evidence)
├── verification/result.md               independent check against acceptance lines
├── research-report/
│   ├── report.md                        researcher-facing narrative
│   └── report.yaml                      machine-readable report metadata
├── observability/
│   ├── token-usage.yaml
│   └── dashboard.yaml
├── preservation/manifest.yaml
└── learning/                            empty unless learning is later approved
```

Report generation is part of that bundle. The reporter role (Goose subrecipe `recipes/subrecipes/report.yaml`) consumes requirements, hashed evidence, specialist analysis and `verification/result.md`. It writes `research-report/report.md` and `research-report/report.yaml`. Model prose is analysis. Only hashed files under `evidence/` and `provenance/` count as observations.

Acceptance lines from the experiment YAML are the checklist the verifier and report must answer.

## Repository structure

```text
experiments/                      LinkML experiment instances (researcher contract values)
schemas/cusimanse.yaml            LinkML schema
schemas/experiment.schema.json    generated / companion JSON Schema
recipes/experiments/              runtime requirements consumed by cmd/cusimanse
recipes/<id>/recipe.yaml          per-experiment Goose recipe
recipes/goose/session.yaml        generic Goose operator recipe
recipes/subrecipes/               evidence-analysis, verification, report
recipes/profiles/                 trusted host + workload profiles
recipes/lima/                     disposable compute declaration
recipes/host/                     host toolchain recipe
recipes/gateway/                  localhost LiteLLM + OmniRoute
recipes/observability/            Numbat, Phoenix, OTEL, ClawMetry, Aegis
recipes/instrumentation/          guest collectors
host-prep/default.yaml            installer allow-list + per-OS fallbacks
policies/host-policy.yaml         authority source of truth
cmd/cusimanse/                    only Go CLI / control-plane entrypoint
internal/policy|preflight|validation|model
roles/  skills/  .agents/         Goose roles and skills
scripts/install.sh|.ps1           first-run bootstrap
scripts/tests/                    validate, runtime, integration
manifest/                         package + tool inventories
runs/                             research outputs (gitignored payload, keep layout)
docs/                             operator, observability, instrumentation guides
```

The retired compiler CLI is not on this branch. Use `go run ./cmd/cusimanse` or an installed `cusimanse` binary.

## Install and first check

Clone this repository and stay on `goose-native`. Do not merge other branches into this worktree for this workflow.

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout goose-native
./scripts/install.sh          # Linux / macOS / WSL2 / Git Bash
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
```

```powershell
.\scripts\install.ps1         # native Windows
```

The installer is idempotent. It only installs tools listed in `host-prep/default.yaml`. Already-present tools are skipped. Missing optional tools are recorded `NOT_DEPLOYED`; they are not treated as passing.

```bash
go run ./cmd/cusimanse doctor
go run ./cmd/cusimanse validate
go run ./cmd/cusimanse preflight
go run ./cmd/cusimanse policy validate
go run ./cmd/cusimanse resolve npm-install-001
go run ./cmd/cusimanse capability list
```

## Access and observability

Access is required to test the project. If a component is not installed, record `NOT_DEPLOYED` or `PARTIAL` in the session — do not invent a pass.

| Surface | Installation mode | How to access | Commands |
|---|---|---|---|
| Cusimanse CLI | `./scripts/install.sh` builds `~/.local/bin/cusimanse`, or `go run ./cmd/cusimanse` | host shell | `cusimanse doctor`, `validate`, `preflight`, `resolve <id>`, `--approved run <id> <session>` |
| Host allow-list | `host-prep/default.yaml` via `scripts/install.sh` or `scripts/install.ps1` | host PATH | `cusimanse tools list`, `cusimanse tools versions`, `cusimanse tools config` |
| Goose operator | official Goose binary from host-prep | Goose session | `goose recipe validate recipes/goose/session.yaml`, `goose recipe validate recipes/npm-install-001/recipe.yaml`, `goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive` |
| LiteLLM gateway | installer Python env | `http://127.0.0.1:4000` | inspect `~/.config/cusimanse/litellm.yaml` (no secrets in Git) |
| OmniRoute | installer npm pin | `http://127.0.0.1:20128` | inspect `~/.config/cusimanse/omniroute.env` |
| Phoenix | installer / pip | `http://127.0.0.1:6006` | `cusimanse observability phoenix` |
| OpenTelemetry | installer | `http://127.0.0.1:4318` | OTLP/HTTP export |
| ClawMetry | installer | `http://127.0.0.1:8900` | `cusimanse observability clawmetry` |
| Numbat | installer / go-install | `~/.numbat/cusimanse.ndjson` | `cusimanse tools numbat` |
| Aegis | installer | `~/.local/share/cusimanse/aegis/` | `cusimanse observability status` |
| Lima/QEMU guest | installer compute category | `limactl shell <vm>` (diagnostic only) | `limactl validate recipes/lima/security-research.yaml` |
| Research report | Goose report subrecipe after evidence | `runs/<session-id>/research-report/` | read `report.md` + `report.yaml` |

Flow: `Goose → LiteLLM :4000 → OmniRoute :20128 → configured provider`. Gateways route models; they are not a security boundary. Policy in `policies/host-policy.yaml` remains authoritative.

## Researcher workflow (`npm-install-001`)

This is the path a researcher or end-user tester follows. YAML files are listed on the step that creates or edits them — there is no separate YAML configuration-set section.

### 0. Choose the experiment

| ID | What you observe |
|---|---|
| `npm-install-001` | pinned `lodash@4.17.21` install with `--ignore-scripts` |
| `npm-lifecycle-001` | controlled local lifecycle execution |
| `npm-threat-001` | controlled local lifecycle fixture |
| `go-install-001` | disposable Linux Go install baseline |

The rest of this section uses `npm-install-001`.

### 1. Declare the research contract

| File | Action |
|---|---|
| `experiments/npm-install-001.yaml` | researcher-facing contract values (`question`, `scope`, `requirements`, `acceptance`, `operator`) |
| `schemas/cusimanse.yaml` | change only if you add/rename slots or enums |
| `schemas/experiment.schema.json` | regenerate when the LinkML schema changes |
| `contracts/npm-install-001.md` | optional narrative copy of authorization and safety |

Keep values only. Do not put `limactl` argv, host npm commands or extra packages in the experiment file.

### 2. Bind runtime requirements and profiles

| File | Action |
|---|---|
| `recipes/experiments/npm-install-001.yaml` | runtime requirements the CLI resolves |
| `recipes/profiles/workload/npm-install.yaml` | fixed workload handler (`ignore-scripts`) |
| `recipes/profiles/host/linux-lima.yaml` | disposable Linux host profile |
| `recipes/profiles/registry.yaml` | register host + workload paths |
| `policies/host-policy.yaml` | only if authority rules must change |

```bash
go run ./cmd/cusimanse resolve npm-install-001
```

Expected: one host profile and one workload profile. Ambiguity or no match fails closed.

### 3. Point Goose at the experiment

| File | Action |
|---|---|
| `recipes/npm-install-001/recipe.yaml` | per-experiment Goose recipe |
| `recipes/goose/session.yaml` | generic operator recipe |
| `recipes/subrecipes/evidence-analysis.yaml` | analysis handoff |
| `recipes/subrecipes/verification.yaml` | independent verification handoff |
| `recipes/subrecipes/report.yaml` | report generation handoff |
| `roles/*.yaml` / `skills/*/SKILL.md` | only if roles or skills change |

```bash
goose recipe validate recipes/goose/session.yaml
goose recipe validate recipes/npm-install-001/recipe.yaml
goose recipe validate recipes/subrecipes/evidence-analysis.yaml
goose recipe validate recipes/subrecipes/verification.yaml
goose recipe validate recipes/subrecipes/report.yaml
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/goose/session.yaml --params experiment=npm-install-001 --interactive
```

Summon is orchestration only. It does not authorize execution.

### 4. Host bootstrap and policy

| File | Action |
|---|---|
| `host-prep/default.yaml` | add a tool only if the experiment truly needs it |
| `recipes/host/security-research.yaml` | host inventory used by docs and installer |
| `recipes/gateway/mandatory.yaml` | localhost gateway declaration |
| `recipes/observability/mandatory.yaml` | observer declaration |

```bash
./scripts/install.sh
go run ./cmd/cusimanse preflight
go run ./cmd/cusimanse policy validate
go run ./cmd/cusimanse policy explain vm
go run ./cmd/cusimanse policy check-all
```

### 5. Approve and run

Execution requires `--approved`. Without it the CLI must refuse.

```bash
SESSION_ID="npm-install-$(date +%Y%m%d-%H%M%S)"
go run ./cmd/cusimanse --approved run npm-install-001 "$SESSION_ID"
```

```text
resolve → policy → session create → provision Lima/QEMU → instrument
→ execute fixed npm-install handler → collect evidence → hash
→ analyze → independently verify → write research-report → preserve → destroy
```

Diagnostic-only Lima commands (not the normal researcher path):

```bash
limactl validate recipes/lima/security-research.yaml
limactl start --name=cusimanse-smoke recipes/lima/security-research.yaml
limactl shell cusimanse-smoke -- bash -lc 'node --version && npm --version && strace -V'
limactl delete --force cusimanse-smoke
```

### 6. Read outputs and finish the report

| File created by the run | Why you open it |
|---|---|
| `runs/$SESSION_ID/session.yaml` | identity and state |
| `runs/$SESSION_ID/evidence/*` | raw observations |
| `runs/$SESSION_ID/provenance/manifest.sha256` | integrity |
| `runs/$SESSION_ID/verification/result.md` | independent verdict |
| `runs/$SESSION_ID/research-report/report.md` | narrative + acceptance answers |
| `runs/$SESSION_ID/observability/` | agent/session telemetry snapshots |

```bash
find "runs/$SESSION_ID" -maxdepth 3 -type f | sort
go run ./cmd/cusimanse observability report "$SESSION_ID"
go run ./cmd/cusimanse policy audit
```

## LinkML schema in the workflow

`schemas/cusimanse.yaml` is the contract language. `experiments/npm-install-001.yaml` is one instance of class `Experiment`.

| Slot / enum | Meaning for a researcher |
|---|---|
| `apiVersion: cusimanse.dev/v1` and `kind: Experiment` | instance header |
| `metadata.id` | must match the filename stem (`npm-install-001`) |
| `spec.question` | the only research question the report may answer |
| `spec.hostPrep` | `default` or `none` |
| `spec.roles` | `operator`, `verifier`, `reporter` |
| `spec.requirements.execution` | `disposable` only |
| `spec.requirements.os` | `linux` or `macos` |
| `spec.requirements.workload` | `npm-install`, `npm-lifecycle`, `npm-threat`, `go-install` |
| `spec.requirements.network` | `localhost-only`, `none`, `controlled` |
| `spec.requirements.instrumentation` | process / syscall / filesystem / network |
| `spec.policyChecks` | `vm`, `network`, `credentials`, `mounts` |
| `spec.acceptance` | checklist copied into verification and the report |
| `spec.operator` | `goose` or `cli` |

When you add a workload or slot:

1. Edit `schemas/cusimanse.yaml`.
2. Refresh `schemas/experiment.schema.json`.
3. Add `experiments/<id>.yaml` that validates against the schema.
4. Add matching `recipes/experiments/<id>.yaml`, profile, Goose recipe and acceptance lines.
5. Run `go run ./cmd/cusimanse validate` and `go run ./cmd/cusimanse resolve <id>`.

The schema does not grant authority. Policy and `--approved` still gate execution.

## Validation and integration tests

```bash
go test ./...
go run ./cmd/cusimanse validate
go run ./cmd/cusimanse preflight
go run ./cmd/cusimanse policy validate
go run ./cmd/cusimanse resolve npm-install-001
go run ./cmd/cusimanse run npm-install-001 && echo 'UNEXPECTED PASS' || echo 'approval gate held'
bash ./scripts/tests/validate.sh
bash ./scripts/tests/integration.sh
bash ./scripts/tests/runtime.sh
CUSIMANSE_RUN_VM_TEST=1 bash ./scripts/tests/runtime.sh
```

CI on this branch runs `go test ./...`, `go run ./cmd/cusimanse` sanity, script syntax, integration tests, and Goose recipe validation when `goose` is on PATH. A green control-plane job is not a completed security experiment.

## Safety, license and contribution

- Do not run the workload on the host.
- `--approved` is required for VM creation and execution.
- Credentials, unrestricted mounts, public MCP and public gateways are denied.
- Preserve and hash evidence before destroy.
- Production-ready project documents on this branch: [AI-DISCLAIMER.md](AI-DISCLAIMER.md), [SECURITY.md](SECURITY.md), [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), [SUPPORT.md](SUPPORT.md), [LICENSE](LICENSE), [NOTICE](NOTICE), [CREDITS.md](CREDITS.md).

> Researchers declare intent and requirements. Goose operates the session. The Go CLI is the capability boundary. Policy controls authority. Lima/QEMU contains execution. Evidence is preserved, independently verified and reported.
