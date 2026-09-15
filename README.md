# Cusimanse (`agentic-native-goose`)

Goose-driven research lab. One typed YAML experiment. Goose plans, checks declared host tools, orchestrates roles, requests approval, runs the compiler, reads evidence, and writes the report.

Beta. Not a certified sandbox.

## Table of contents

1. [Layers](#layers)
2. [Architecture](#architecture)
3. [Components](#components)
4. [Research outputs (`runs/`)](#research-outputs-runs)
5. [Repository structure](#repository-structure)
6. [Which shell](#which-shell)
7. [Host bootstrap](#host-bootstrap)
8. [Install](#install)
9. [Researcher workflow (npm-install-001)](#researcher-workflow-npm-install-001)
10. [YAML configuration set](#yaml-configuration-set)
11. [Access and observability](#access-and-observability)
12. [Report generation](#report-generation)
13. [Compiler commands](#compiler-commands)
14. [Validation and integration tests](#validation-and-integration-tests)
15. [Safety](#safety)

## Layers

| Layer | Files | Who runs it |
|---|---|---|
| Experiment | `experiments/<id>.yaml` | Researcher |
| Host bootstrap | `host-prep/default.yaml` + `scripts/install.sh` | Normal shell first, then Goose check |
| Roles / skills | `roles/`, `skills/` | Goose Summon |
| Operator recipe | `recipes/goose/session.yaml` | Goose session |
| Compiler | `cmd/compile` | Goose *or* normal shell |

## Architecture

Five planes: contract → Goose → compiler → runtime → sidecars.

![Cusimanse layered architecture](docs/architecture/agentic-native-layers.svg)

## Components

| Role | Skills |
|---|---|
| operator | experiment-operate, host-prep-declared |
| verifier | evidence-read, evidence-analysis, verification |
| reporter | report |

## Research outputs (`runs/`)

`session.yaml`, `evidence/`, hashes, `verification/result.md`, `research-report/report.md`.

## Repository structure

```text
host-prep/default.yaml     allow-list + per-OS install fallbacks
scripts/install.sh         Linux / macOS / Git-Bash Windows
scripts/install.ps1        native Windows (winget/scoop/choco)
```

## Which shell

| Task | Surface |
|---|---|
| Clone + first install | **Normal shell** (`./scripts/install.sh` or `scripts/install.ps1`) |
| Tests | **Normal shell** |
| `compile host-prep` check | **Either** |
| Plan / approve / Summon | **Goose session** |
| Guest workload | **Guest VM** |

## Host bootstrap

Declared in `host-prep/default.yaml` (`managers` + per-tool `install` maps). The installer is **idempotent**: if `check` already succeeds, that tool is skipped.

Order per tool:

1. Already on `PATH` → skip
2. Native manager — Linux `apt-get`/`dnf`/`pacman`/`zypper`/`apk`, macOS `brew`, Windows `winget` then `scoop` then `choco`
3. Fallback `official-binary` / `go-install` / `npm-global` / `pip` as written in the YAML
4. Optional miss → `NOT_DEPLOYED` (script does not abort)

```bash
# Linux / macOS / WSL2 / Git Bash — normal shell
./scripts/install.sh
./scripts/install.sh          # safe to repeat
```

```powershell
# native Windows — PowerShell
.\scripts\install.ps1
```

```bash
# Goose or bash — check only, no surprise packages
go run ./cmd/compile host-prep npm-install-001
```

Compute: Lima/QEMU on Linux and macOS; Multipass is the Windows-native fallback. Guests for npm experiments still prefer Lima on Unix or WSL2.

## Install

```bash
git checkout agentic-native-goose
./scripts/install.sh
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
```

## Researcher workflow (npm-install-001)

Normal shell validate → Goose `session.yaml` → approve → read `runs/`.

## YAML configuration set

`experiments/npm-install-001.yaml`, `host-prep/default.yaml`, `recipes/goose/session.yaml`, `roles/` + `skills/`, `policies/host-policy.yaml`.

## Access and observability

Missing optional tools stay `NOT_DEPLOYED`.

## Report generation

Cite hashed evidence. Acceptance lines are the checklist.

## Compiler commands

```bash
go run ./cmd/compile catalog
go run ./cmd/compile validate <id>
go run ./cmd/compile host-prep <id>
go run ./cmd/compile execute <id> --approved
```

## Validation and integration tests

```bash
go test ./internal/compiler ./cmd/compile ./cmd/cusimanse
bash ./scripts/tests/integration.sh
```

## Safety

Do not run the workload on the host. `--approved` is required.
