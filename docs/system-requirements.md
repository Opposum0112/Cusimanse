# System requirements

Cusimanse is designed for Linux and macOS research hosts, with Windows supported through WSL2. The disposable VM is the workload execution boundary; the host provides orchestration, virtualization, evidence collection and policy controls.

## Supported host strategy

| Host | Installation strategy | Notes |
|---|---|---|
| Linux | Runtime-detect `apt`, `dnf`, `pacman`, `zypper` or `apk` | Distro-neutral bootstrap path with package-family mappings |
| openSUSE | `zypper` + Lima archive fallback | Handles hosts where Lima is absent from configured repositories |
| macOS | Homebrew + Lima/QEMU | Supported direct host path |
| Windows | WSL2 + Linux bootstrap | Recommended cross-platform path; native Windows Lima is not claimed |

The setup detects x86_64/amd64 and ARM64/aarch64. Optional tools without a verified installer are reported as `NOT_DEPLOYED`.

## Mandatory host requirements

| Area | Requirement |
|---|---|
| OS | Linux, macOS, or Windows through WSL2 |
| CPU | Hardware virtualization recommended; 4+ cores recommended |
| RAM | 8 GB minimum; 16 GB+ recommended |
| Disk | 20 GB minimum; 40–50 GB+ recommended for VM images/evidence |
| Runtime | Lima + QEMU |
| Languages | Go, Python 3, Ruby |
| Utilities | Git, Bash, curl |
| Agent | At least one selected primary terminal agent |
| Network | Outbound access for installation and permitted enrichment |

## One-command researcher preparation

From the repository root:

```bash
go run ./cmd/cusimanse-host
```

Or use the root-safe wrapper from anywhere inside the checkout:

```bash
./scripts/cusimanse-host.sh
```

The interactive front door offers baseline, extended research, observability, complete-workstation and check/repair profiles. The complete profile attempts all supported primary-agent adapters as well as control/research/observability components.

If checkout execute metadata was lost, bootstrap safely with:

```bash
bash ./scripts/prerequisites.sh
```

## Direct prerequisite bootstrap

```bash
bash ./scripts/prerequisites.sh
```

Interactive choices:

1. Baseline host + VM prerequisites
2. Extended security-research/control/learning
3. Observability/governance
4. Complete researcher workstation + primary agents
5. Check/repair only

For automation:

```bash
CUSIMANSE_NONINTERACTIVE=1 CUSIMANSE_PROFILE=4 bash ./scripts/prerequisites.sh
```

The script repairs `.sh` execute bits, configures user-local `PATH`, `GOPATH` and `GOBIN`, detects the OS/architecture/package manager, installs required host dependencies, installs/verifies Lima and QEMU, and reports unavailable optional integrations honestly.

### Lima installation

Lima is installed in this order:

1. Native package manager where available.
2. Official Lima release archive for the detected OS and CPU architecture when the package is unavailable.

The archive installation is placed under `~/.local` and verifies `limactl` plus Lima support files.

## Interactive host preflight

```bash
bash ./scripts/agent-preflight.sh
```

Modes:

1. Baseline host check/repair
2. Baseline + selected primary-agent check
3. Full capability audit across the architecture planes

The preflight can offer to invoke the prerequisite installer when mandatory dependencies are missing. It checks Git, Bash, curl, Python 3, Ruby, Go, QEMU, Lima, virtualization capability where detectable, repository script execute bits, the selected primary agent, control utilities, observability packages, policy files and learning assets.

## Agent observability and governance plane

Agent execution should emit OpenTelemetry traces/metrics/logs into the observability plane. Phoenix is the research observability integration. Numbat and Aegis remain integration targets until verified adapters/installers are available.

```text
Primary Agent
     |
     v
OpenTelemetry SDK/exporters
     |
     +------> Phoenix
     +------> Numbat (verified adapter required)
     +------> Aegis (verified adapter required)
     |
     v
Evidence / audit plane
```

Observability/governance improves tracing, detection and auditability. It is **not** the VM security boundary.

## Plane readiness

| Plane | Prepared by host bootstrap | Verification |
|---|---|---|
| Host/researcher | Git, Bash, curl, Python, Ruby, Go, environment | preflight |
| Policy | policy files + policyctl build/validation | `./policyctl validate` |
| Agent/operator | Goose, Prime Agent, Hermes installation attempts | `agent --help` / preflight |
| Control | YAML tooling, Taskflow/LangGraph dependencies where selected | project validation |
| Observability/governance | OpenTelemetry/Phoenix; Numbat/Aegis only when verified | full preflight audit |
| Execution | Lima + QEMU | `limactl --version`, VM lifecycle check |
| Evidence/case | repository evidence layout + hashing utilities | artifact inspection |
| Learning | `.agents/skills` + promotion recipes | validation/review |

## Execute-bit and environment checks

CI and local validation should verify:

```bash
find scripts -type f -name '*.sh' -exec test -x {} \; -print
bash -n scripts/prerequisites.sh
command -v go python3 qemu-system-x86_64 limactl
printf '%s\n' "$PATH"
printf '%s\n' "$GOPATH"
printf '%s\n' "$GOBIN"
```

A missing executable bit, missing mandatory binary, invalid path, or unavailable required capability must fail validation or be reported as `NOT_DEPLOYED`; it must not be silently treated as success.

## Security boundary reminder

The installer and preflight prepare the researcher host; they do **not** make the host itself a security boundary. Untrusted workloads execute in the disposable Lima/QEMU VM. `policyctl` remains host-side and outside the agent control plane. Provider credentials remain researcher-managed and are never placed in recipes, skills or MCP arguments.
