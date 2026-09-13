# 🦝 Cusimanse

> Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.

Cusimanse prepares a researcher host, selects one primary terminal agent, runs the workload inside a disposable Lima/QEMU VM, collects evidence, independently verifies findings, and preserves artifacts before VM destruction.

## Architecture

```mermaid
flowchart TB
 H["HOST / RESEARCHER\nInteractive preparation + preflight"] --> P["POLICY\npolicyctl validate"]
 H --> A["PRIMARY AGENT\nPrime Agent · Hermes · Goose"]
 A --> C["CONTROL\nYAML · Taskflow · LangGraph · MCP"]
 C --> V["EXECUTION BOUNDARY\nLima + QEMU + disposable VM"]
 C --> O["OBSERVABILITY / GOVERNANCE\nOpenTelemetry · Phoenix · Numbat · Aegis"]
 V --> W["UNTRUSTED WORKLOAD"]
 V --> E["EVIDENCE / CASE\nartifacts · telemetry · audit · hashes"]
 O --> E
 E --> L["LEARNING\nCANDIDATE → replay → verification → approval → VALIDATED"]
 L --> A
 P -. independent host constraint .-> V
```

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

## Researcher deployment — one front door

From the repository root:

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout architecture-refactor
go run ./cmd/cusimanse-host
```

The Go program is under `cmd/cusimanse-host`, **not `scripts/`**. If you are currently inside `scripts/`, use the root-safe wrapper instead:

```bash
./cusimanse-host.sh
```

or from anywhere inside the checkout:

```bash
./scripts/cusimanse-host.sh
```

The interactive front door detects the host, repairs script execute bits, invokes the comprehensive prerequisite installer, offers the complete researcher profile, runs preflight and can run host-side policy validation.

### Interactive profiles

`bash ./scripts/prerequisites.sh` offers:

1. Baseline host + VM prerequisites
2. Extended security-research/control/learning tooling
3. Observability/governance tooling
4. **Complete researcher workstation** — all supported planes plus Goose, Prime Agent and Hermes installation attempts
5. Check/repair only

For scripted use, select a profile explicitly:

```bash
CUSIMANSE_NONINTERACTIVE=1 CUSIMANSE_PROFILE=4 bash ./scripts/prerequisites.sh
```

The preflight is also interactive and offers baseline, selected-agent and full capability-audit modes:

```bash
bash ./scripts/agent-preflight.sh
```

It can offer to bootstrap missing host prerequisites before continuing. Both scripts repair repository `.sh` execute bits before validation.

## OS and distribution support

| Host | Strategy |
|---|---|
| Linux | Runtime detection of `apt`, `dnf`, `pacman`, `zypper` or `apk`; distro-specific packages |
| openSUSE | `zypper`; Lima native package first, official Lima release archive fallback |
| macOS | Homebrew for host dependencies and Lima/QEMU |
| Windows | **WSL2** recommended; run Cusimanse inside the Linux environment |

The bootstrap detects x86_64/amd64 and ARM64/aarch64. It does not pretend every research product has a native installer on every OS. Unsupported/unverified optional components are reported as `NOT_DEPLOYED`.

For Lima, the installation order is **native package manager → official Lima release archive fallback**. Windows uses WSL2 because the Cusimanse Lima/QEMU execution path is not currently treated as a native Windows path.

## Plane commands and interfaces

| Plane | Components | Commands / interfaces |
|---|---|---|
| **Host / Researcher** | bootstrap, environment, preflight, Go setup | `go run ./cmd/cusimanse-host`, `./scripts/cusimanse-host.sh`, `bash ./scripts/prerequisites.sh`, `bash ./scripts/agent-preflight.sh` |
| **Policy** | independent host-side policy | `./policyctl validate`, `./policyctl --help` |
| **Agent / Operator** | primary terminal agent | `prime-agent`, `hermes`, `goose`, `CUSIMANSE_PRIMARY_ADAPTER` |
| **Control** | recipes, taskflow, state, transformations | YAML, Taskflow, LangGraph, scoped MCP, `yq`, `jq` |
| **Observability / Governance** | tracing, telemetry, agent/runtime visibility | OpenTelemetry, Phoenix, Numbat, Aegis |
| **Execution** | disposable VM/OS boundary | `limactl list`, `limactl shell <vm>`, `limactl stop <vm>`, `limactl delete <vm>` |
| **Evidence / Case** | artifacts, telemetry, audit, integrity | `find evidence blackboard runs -type f -print`, `sha256sum <file>` |
| **Learning** | skills, replay, verification, promotion | `find .agents/skills -name SKILL.md`, `git diff -- .agents/skills/`, `cat recipes/learning/skill-promotion.yaml` |

## Primary agents

The complete workstation profile attempts to install the supported adapters. Provider/model credentials remain researcher-managed and must not be stored in Git.

```bash
export CUSIMANSE_PRIMARY_ADAPTER=prime-agent
prime-agent --help
prime-agent

export CUSIMANSE_PRIMARY_ADAPTER=hermes
hermes --help
hermes

export CUSIMANSE_PRIMARY_ADAPTER=goose
goose --help
goose
```

Use exactly one primary operator shell for a case.

## Control and workflow

```bash
find recipes -name '*.yaml' -print
yq '.' recipes/agents/self-learning-primary.yaml
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/architecture-refactor.sh
```

Lifecycle:

```text
Discover → Validate → Retrieve → Plan → Review → Approve
→ Provision VM → Instrument → Execute → Collect → Analyze
→ Verify → Learn → Promote → Preserve → Destroy
```

## Observability / governance

OpenTelemetry is the tracing foundation. Phoenix is the research observability integration. Numbat and Aegis are integration targets that require verified adapters/installers before being considered deployed.

```bash
python3 -c 'import importlib.util; print("opentelemetry:", bool(importlib.util.find_spec("opentelemetry"))); print("phoenix:", bool(importlib.util.find_spec("phoenix")))'
phoenix --help
numbat --help
aegis --help
```

## Execution boundary

Untrusted workload commands execute inside the disposable VM through the selected agent workflow, not directly from the normal researcher host shell.

```bash
limactl list
limactl shell <vm>
limactl stop <vm>
limactl delete <vm>
```

Preserve evidence before destroying the VM.

## Evidence and learning

```bash
find evidence blackboard runs -type f -print 2>/dev/null
find experiments/go-install-001 -maxdepth 4 -type f -print 2>/dev/null
sha256sum <file>

find .agents/skills -name SKILL.md -print
git diff -- .agents/skills/
cat recipes/learning/skill-promotion.yaml
```

A learned procedure remains **CANDIDATE** until replay on a distinct artifact, independent verification, provenance and human approval gates pass.

## Preflight and validation

Preflight checks repository execute bits, baseline host dependencies, QEMU, Lima, virtualization capability where detectable, the selected primary adapter and, in full-audit mode, control/observability/policy/learning components.

```bash
bash ./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/architecture-refactor.sh
```

`PASS` in validation means the corresponding check passed; it is not a claim of runtime sandbox security. Runtime PASS requires actual experiment evidence and independent verification.

## System requirements

- Linux or macOS directly; Windows through WSL2.
- 4+ CPU cores recommended; 16 GB RAM recommended for VM + observability workloads.
- 40+ GB free disk recommended for VM images/evidence.
- Hardware virtualization enabled where applicable.
- Git, Bash, curl, Python 3, Ruby, Go, QEMU and Lima.
- One supported primary terminal agent.
- Network access for installation and permitted research enrichment.

See `docs/system-requirements.md`.

## Security invariants

- Lima/QEMU disposable VM is the workload execution boundary.
- Normal host shell and primary-agent shell are distinct contexts.
- `policyctl` is host-side and outside the agent control plane.
- Host credentials are not exposed to workloads or learned skills.
- Public MCP exposure is denied by default.
- Observability/governance is not an isolation boundary.
- Retrieval does not grant execution authority.
- Evidence is preserved before VM destruction.
- Learned capabilities require replay and independent verification before promotion.
