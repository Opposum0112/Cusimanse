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

## Researcher deployment — interactive front door

The preferred setup is the Go host-preparation program. **Run it from the repository root**:

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout architecture-refactor
go run ./cmd/cusimanse-host
```

`cmd/cusimanse-host` is at the repository root; it is not under `scripts/`. The program also locates the repository root automatically when started from a repository subdirectory, or you can set `CUSIMANSE_ROOT`.

The interactive installer can:

1. Install baseline host + VM prerequisites.
2. Install extended security-research, control and learning tooling.
3. Install the OpenTelemetry/Phoenix observability foundation and check Numbat/Aegis.
4. Install the supported primary-agent adapters: Goose, Prime Agent and Hermes.
5. Run comprehensive preflight/capability checks.
6. Run host-side policy validation.

### Non-interactive / manual mode

```bash
bash ./scripts/prerequisites.sh
bash ./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

For automated environments, `CUSIMANSE_NONINTERACTIVE=1` selects the baseline path without prompts. Additional profiles can be selected with environment variables:

```bash
CUSIMANSE_INSTALL_PRODUCTION_PROFILE=1 bash ./scripts/prerequisites.sh
CUSIMANSE_INSTALL_OBSERVABILITY=1 bash ./scripts/prerequisites.sh
CUSIMANSE_INSTALL_AGENTS=1 bash ./scripts/prerequisites.sh
```

The scripts repair `chmod +x` for repository shell controls before proceeding, so a checkout that lost executable metadata can still be bootstrapped with `bash`.

## OS and distribution support

- **Linux:** detects `apt`, `dnf`, `pacman`, `zypper` and `apk` and maps packages to the detected distribution family.
- **openSUSE:** `zypper` is detected; if Lima is not available as a package, the installer falls back to the official Lima release archive.
- **macOS:** uses Homebrew for host dependencies and Lima when available.
- **Windows:** use **WSL2** and run Cusimanse inside the Linux environment. Native Windows Lima execution is not currently treated as supported. Hardware virtualization must be available to WSL2.
- CPU architecture is detected for x86_64/amd64 and ARM64/aarch64 where supported.

Lima installation uses this order: **native package manager → official Lima release archive fallback**. The fallback installs the Lima user-space files under `~/.local` and verifies `limactl`.

## Plane commands and interfaces

| Plane | Components | Commands / interfaces |
|---|---|---|
| **Host / Researcher** | bootstrap, environment, preflight, Go setup | `go run ./cmd/cusimanse-host`, `scripts/prerequisites.sh`, `scripts/agent-preflight.sh`, `git status` |
| **Policy** | independent host-side policy | `./policyctl validate`, `./policyctl --help` |
| **Agent / Operator** | primary terminal agent | `prime-agent`, `hermes`, `goose`, `CUSIMANSE_PRIMARY_ADAPTER` |
| **Control** | recipes, taskflow, state, transformations | YAML, Taskflow, LangGraph, scoped MCP, `yq`, `jq` |
| **Observability / Governance** | tracing, telemetry, agent/runtime visibility | OpenTelemetry, Phoenix, Numbat, Aegis |
| **Execution** | disposable VM/OS boundary | `limactl list`, `limactl shell <vm>`, `limactl stop <vm>`, `limactl delete <vm>` |
| **Evidence / Case** | artifacts, telemetry, audit, integrity | `find evidence blackboard runs -type f -print`, `sha256sum <file>` |
| **Learning** | skills, replay, verification, promotion | `find skills -name SKILL.md`, `git diff -- skills/`, `cat recipes/learning/skill-promotion.yaml` |

## Preflight

`agent-preflight.sh` is the required final host gate before agent execution. It verifies:

- repository script execute bits;
- Git, Bash, curl, Python 3, Ruby and Go;
- QEMU system emulator;
- Lima/`limactl` and basic runtime availability;
- virtualization capability where detectable;
- selected `CUSIMANSE_PRIMARY_ADAPTER`, when configured.

It automatically invokes the prerequisite bootstrap if required host components are missing, then checks them again.

```bash
./scripts/agent-preflight.sh
```

## Primary agents

Install one or all supported adapters using the interactive host installer. Select exactly one primary agent for a research case:

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

The selected agent operates the case. `policyctl` remains outside the agent control plane.

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

OpenTelemetry is the tracing foundation. Phoenix provides agent tracing/observability. Numbat and Aegis are integrations that must be verified before being considered deployed.

```bash
python3 -c 'import importlib.util; print("opentelemetry:", bool(importlib.util.find_spec("opentelemetry"))); print("phoenix:", bool(importlib.util.find_spec("phoenix")))'
phoenix --help
numbat --help
aegis --help
```

Missing optional adapters are reported as **NOT_DEPLOYED** rather than silently treated as available.

## Execution boundary

Untrusted workload commands belong inside the disposable VM and are driven by the selected agent workflow, not the normal researcher host shell.

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

find skills -name SKILL.md -print
git diff -- skills/
cat recipes/learning/skill-promotion.yaml
```

A learned procedure remains **CANDIDATE** until replay on a distinct artifact, independent verification, provenance and human approval gates pass.

## System requirements

- Linux or macOS directly; Windows through WSL2.
- 4+ CPU cores recommended and 16 GB RAM recommended for VM + observability workloads.
- 40+ GB free disk recommended for VM images and evidence.
- Hardware virtualization enabled where applicable.
- Git, Bash, curl, Python 3, Ruby, Go, QEMU and Lima.
- One supported primary terminal agent.
- Network access for installation and permitted research enrichment.

See `docs/system-requirements.md`.

## Validation

```bash
./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/architecture-refactor.sh
git status --short --branch
```

Static validation is not runtime PASS. A research result is PASS only when the required runtime evidence and verification gates are actually satisfied.

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
