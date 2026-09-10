# AI Security Research Lab

[![License: MIT](https://img.shields.io/badge/License-MIT-0B6E4F.svg)](LICENSE)
[![Status: Lab baseline](https://img.shields.io/badge/status-lab%20baseline-1B4332.svg)](#project-status)
[![SPDX](https://img.shields.io/badge/SPDX-MIT-2D6A4F.svg)](NOTICE)

Isolated, reproducible laboratory for studying **AI agents**, **model routing**,
and **host/VM instrumentation** during controlled software installs.

This repository is the final deployment package for a local research lab on an
Intel MacBook Pro (A1278, 16 GB RAM) running Parrot OS, with Lima + QEMU
disposable VMs and a harness-neutral agent stack.

It is a **personal lab**, not a hosted product. Untrusted work runs in
throwaway VMs. Host credentials stay off those VMs.

**Install:** jump to [Installation](#installation) (clone → apt → Lima → `labctl`).

![Lab architecture](ai-security-lab-architecture.png)

## Why this exists

AI coding agents can install packages, follow untrusted instructions, and
leave a large forensic footprint. This lab makes that activity:

- **Isolated** — disposable Lima/QEMU VMs, no host credential mounts
- **Observable** — process, syscall, filesystem, DNS, packet, and agent traces
- **Reproducible** — experiment manifests, hashes, Git checkpoints
- **Honest** — if a component was not deployed, it is marked `NOT_DEPLOYED`

The first mandatory integration experiment is
[`go-install-001`](experiments/go-install-001): a pinned Go package install
inside a disposable VM, used as an end-to-end platform test rather than a
language tutorial.

## Architecture principle

The platform is **harness-neutral**. Antigravity CLI is a first-class harness,
but it is not the security boundary and does not replace Lima, Aegis, Numbat,
the model gateway, or the evidence stack.

```text
User → Orchestrator → Agent/Harness → HarnessRouter → Model Gateway
    → MCP / Aegis / Numbat → Lima/QEMU → Instrumentation
    → Evidence → Forensics → Independent Verification → Report → Git
```

| Plane | Role | Typical components |
|---|---|---|
| Control | Tasking, approvals, agent lifecycle | Orchestrator, blackboard, HarnessRouter |
| Model | Provider routing and budgets | LiteLLM **or** OmniRoute |
| Agent | Planning, build, review, report | Antigravity, Grok Build, OpenCode, Goose, Codex |
| Capability | Tool policy and visibility | MCP, Aegis, Numbat |
| Execution | Disposable compute | Lima, QEMU, Docker **or** Podman |
| Observation | Workload telemetry | strace, bpftrace, Tetragon, tcpdump, Zeek, Suricata, mitmproxy |
| Evidence | Hash, reduce, verify | JSONL, PCAP, filesystem diffs |
| AI observability | Agent traces | OpenTelemetry, OpenInference, Phoenix |

LiteLLM and OmniRoute are **alternatives**. Docker and Podman are **alternatives**.
Do not stack duplicates unless you are explicitly testing composition.

![Experiment workflow](ai-security-lab-experiment-workflow.png)

## Repository layout

```text
ai-security-lab/
├── README.md                          This file
├── LICENSE                            MIT
├── NOTICE                             Copyright and responsible-use notice
├── SECURITY.md                        Lab rules and private reporting
├── AGENTS.md                          Repository-wide agent rules
├── PACKAGE-MANIFEST.json              SHA-256 inventory of the deployment pack
├── 01-deployment-architecture.md      Authoritative architecture
├── 02-system-requirements.md          Host, VM, storage, software
├── 03-deployment-runbook.md           Ordered install and configuration
├── 04-security-model.md               Threat model, isolation, policy
├── 05-multi-agent-operating-model.md  Agents, routing, handoffs
├── 06-observability-and-evidence.md   AI + runtime telemetry
├── 07-experiment-framework.md         Disposable experiment contract
├── 08-go-install-001.md               First end-to-end integration test
├── 09-operations-and-maintenance.md   Updates, backups, lifecycle
├── 10-validation-and-acceptance.md    Acceptance matrix
├── 11-current-antigravity-reference.md
├── state.yaml                         Deployment state template
├── profiles.yaml                      VM resource / security profiles
├── blackboard-schema.md               Shared multi-agent state contract
├── skills-registry.md                 Versioned skills model
├── antigravity/                       Agents, skills, MCP templates
├── scripts/                           labctl — create stack + per-stage experiments
├── packages/labprobe/                 In-repo Go module (go-install-001 target)
├── infra/                             Generated localhost stack (Lima, gateway, OTel)
├── policies/                          Permission tiers and mount denylist
└── experiments/                       One experiment per document stage
```

## Documents

| File | Purpose |
|---|---|
| [Installation](#installation) | Clone, host packages, Lima, `labctl`, first experiment |
| [01-deployment-architecture.md](01-deployment-architecture.md) | Authoritative architecture and component responsibilities |
| [02-system-requirements.md](02-system-requirements.md) | Host, VM, storage, memory and software requirements |
| [03-deployment-runbook.md](03-deployment-runbook.md) | Ordered installation and configuration procedure |
| [04-security-model.md](04-security-model.md) | Threat model, permissions, isolation and policy |
| [05-multi-agent-operating-model.md](05-multi-agent-operating-model.md) | Agents, harnesses, routing and handoffs |
| [06-observability-and-evidence.md](06-observability-and-evidence.md) | AI observability, runtime telemetry and forensic evidence |
| [07-experiment-framework.md](07-experiment-framework.md) | Reproducible disposable experiment model |
| [08-go-install-001.md](08-go-install-001.md) | First end-to-end integration experiment |
| [09-operations-and-maintenance.md](09-operations-and-maintenance.md) | Updates, backups, troubleshooting and lifecycle |
| [10-validation-and-acceptance.md](10-validation-and-acceptance.md) | Platform acceptance criteria and test matrix |
| [AGENTS.md](AGENTS.md) | Rules every agent in this repo must follow |
| [SECURITY.md](SECURITY.md) | Lab-only use and private vulnerability reporting |
| [scripts/README.md](scripts/README.md) | `labctl` — generate the stack and run each stage |

## Non-negotiable lab rules

1. Do not execute unknown installers or experiments directly on the host when
   they can run inside a disposable VM.
2. Do not give agents unrestricted host filesystem access or host credentials.
3. Start instrumentation **before** the target action.
4. Preserve and hash evidence **before** deleting a VM.
5. Do not commit secrets.
6. Do not silently bypass MCP, Aegis, Numbat, or other controls to make a test
   pass.
7. Do not claim a component was exercised unless it actually was.

Full agent rules: [AGENTS.md](AGENTS.md).

## Installation

Do this **in order**. Do not skip preflight. Do not install unknown
packages on the host when they can run inside a disposable VM.

Target host: **Parrot OS**, Intel x86_64, 16 GB RAM, 50 GB+ free disk,
VT-x / KVM. Full spec: [02-system-requirements.md](02-system-requirements.md).

### 1. Clone this repository

The repo is private. Use an account that can read
`Opposum0112/ai-security-lab`.

```bash
git clone https://github.com/Opposum0112/ai-security-lab.git
cd ai-security-lab
```

SSH:

```bash
git clone git@github.com:Opposum0112/ai-security-lab.git
cd ai-security-lab
```

### 2. Install host packages (Parrot / Debian)

Pick **one** container runtime (Podman *or* Docker), not both.

```bash
sudo apt update
sudo apt install -y \
  git curl wget ca-certificates \
  python3 python3-venv \
  build-essential \
  golang-go \
  qemu-system-x86 qemu-utils \
  jq ripgrep miller \
  strace lsof tcpdump \
  podman
```

If you prefer Docker instead of Podman:

```bash
sudo apt install -y docker.io
sudo usermod -aG docker "$USER"
# log out and back in so the group applies
```

`yq` is often not in the default repos. If `apt install yq` fails, skip it
for now — `labctl` does not need it.

### 3. Install Lima

Lima is required for disposable experiment VMs. Review the installer
**before** running it.

```bash
curl -fsSL https://lima-vm.io/install.sh -o /tmp/lima-install.sh
less /tmp/lima-install.sh
sh /tmp/lima-install.sh
limactl --version
qemu-system-x86_64 --version
```

### 4. Confirm virtualization

```bash
uname -m          # expect x86_64
nproc
free -h           # expect ~16 GB class
df -h .
ls -l /dev/kvm    # must exist and be readable
```

If `/dev/kvm` is missing, fix VT-x / KVM on the host before continuing.

### 5. Bootstrap the lab with `labctl`

`labctl` is stdlib Python 3. No `pip install`.

```bash
chmod +x scripts/bin/labctl
./scripts/bin/labctl stages
./scripts/bin/labctl init
./scripts/bin/labctl preflight --apply
./scripts/bin/labctl accept
```

| Command | What it does |
|---|---|
| `init` | Writes `infra/`, `policies/`, and one experiment per document stage |
| `preflight --apply` | Checks CPU, RAM, disk, KVM, QEMU, Lima; records facts in `state.yaml` |
| `accept` | Prints the seven-level matrix from [10-validation-and-acceptance.md](10-validation-and-acceptance.md) |

`init` only writes files. Starting processes needs `--apply` (next steps).

Expected first-run scores: host tools **PASS** or **PARTIAL**. Gateway,
Phoenix, and `go-install-001` stay **NOT_DEPLOYED** until you start them.

### 6. Optional — observability stack (localhost only)

Binds `127.0.0.1:6006` (Phoenix) and `127.0.0.1:4317` (OTel). Do not publish
these ports.

```bash
./scripts/bin/labctl stack up observability --apply
```

Stop later with:

```bash
./scripts/bin/labctl stack down observability --apply
```

### 7. Optional — model gateway (localhost only)

LiteLLM **or** OmniRoute, not both. This repo ships the LiteLLM option.

```bash
cp infra/gateway/.env.example infra/gateway/.env
# edit infra/gateway/.env — never commit it
./scripts/bin/labctl stack up gateway --apply
```

The gateway listens on `127.0.0.1:4000`.

### 8. Optional — Antigravity CLI

`labctl` will **not** run this for you. Review the script, then install from
the [official docs](https://antigravity.google/docs/cli/install/):

```bash
curl -fsSL https://antigravity.google/cli/install.sh -o /tmp/agy-install.sh
less /tmp/agy-install.sh
bash /tmp/agy-install.sh
agy --help
```

Workspace agents and skills are already in [`.agents/`](.agents) and
[`antigravity/`](antigravity). Other harnesses (OpenCode, Goose, Codex) are
optional — install only what the current milestone needs.

### 9. First experiment (`go-install-001`)

Do not run any other experiment until this one finishes or its failure is
committed. Workload: in-repo Go module
[`packages/labprobe`](packages/labprobe) inside a disposable Lima VM.

```bash
./scripts/bin/labctl experiment list
./scripts/bin/labctl experiment run go-install-001
# after reviewing experiments/go-install-001/lima.yaml (mounts must stay empty):
./scripts/bin/labctl experiment run go-install-001 --apply
```

Authoritative procedure: [08-go-install-001.md](08-go-install-001.md).

### 10. Daily checks

```bash
./scripts/bin/labctl doctor
./scripts/bin/labctl status
```

On 16 GB RAM: one heavy Lima VM at a time, several GB of host headroom,
hosted model APIs instead of large local models.

More commands: [scripts/README.md](scripts/README.md). Ordered install
detail: [03-deployment-runbook.md](03-deployment-runbook.md).

## First milestone: `go-install-001`

The workload is a pinned **in-repo** Go package
([`packages/labprobe`](packages/labprobe)) installed inside a disposable VM.
The real goal is to exercise the **entire** control path:

Planner → Researcher → Builder → Security Reviewer → HarnessRouter →
gateway → MCP → Aegis → Numbat → Lima/QEMU → instrumentation → evidence →
reduction → forensics → independent verification → report → Git.

The experiment **passes** only when the workload ran in the VM, evidence was
preserved, routing was recorded, important findings were independently
verified, the integration scorecard and reproducibility manifest exist, the VM
was cleaned up, and the result was committed.

## Project status

| Item | State |
|---|---|
| Deployment package | Published |
| Host bootstrap | `./scripts/bin/labctl init` then follow the runbook |
| `labctl` | Python 3 stdlib control plane in `scripts/` |
| `labprobe` | In-repo Go module, target for `go-install-001` |
| `go-install-001` | Scaffolded, not yet executed |
| Secrets in Git | None intended — see `.gitignore` |

`state.yaml` is a template. Update it as components are installed.

## License

Copyright (c) 2026 Opposum0112.

This project is licensed under the **MIT License**. See [LICENSE](LICENSE)
and [NOTICE](NOTICE).

Third-party tools named in these documents (Antigravity CLI, Lima, QEMU,
LiteLLM, Go, and others) remain under their own licenses. This repository does
not relicense them.

## Responsible use

This lab is for systems you own or have explicit permission to operate.

- Isolated VMs only for untrusted installs
- No testing of other people's machines, networks, or accounts
- No public exposure of gateways, MCP servers, or dashboards
- Findings must cite evidence; unverified claims stay unverified

See [SECURITY.md](SECURITY.md) to report a problem in this repository.
