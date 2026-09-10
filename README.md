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
└── experiments/go-install-001/        First experiment scaffolding
```

## Documents

| File | Purpose |
|---|---|
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

## Getting started

This package is documentation and scaffolding. It does not install the lab for
you. Follow the runbook in order.

1. Confirm the host matches [02-system-requirements.md](02-system-requirements.md)
   (Intel x86_64, 16 GB RAM, Parrot OS, VT-x / KVM).
2. Work through [03-deployment-runbook.md](03-deployment-runbook.md)
   (Git bootstrap → host preflight → harnesses → Lima/QEMU → gateway → MCP →
   Aegis → Numbat → observability → instrumentation).
3. Record versions and choices in [`state.yaml`](state.yaml). Never put API keys
   in Git.
4. Run **only** [`experiments/go-install-001`](experiments/go-install-001)
   as the first integration test. Pin an explicit `package@version` during
   planning. See [08-go-install-001.md](08-go-install-001.md).
5. Do not start a second experiment until `go-install-001` has passed, or its
   failure is fully documented and committed.

On 16 GB RAM, keep **one** heavy Lima VM active, leave several GB of host
headroom, and prefer hosted model APIs over large local models.

## First milestone: `go-install-001`

The workload is a pinned Go package installation inside a disposable VM. The
real goal is to exercise the **entire** control path:

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
| Host bootstrap | Operator follows the runbook |
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
