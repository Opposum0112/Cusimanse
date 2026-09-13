# System requirements

Cusimanse is designed for Linux and macOS research hosts. The disposable VM is the workload execution boundary; host requirements support orchestration, virtualization and evidence collection.

## Mandatory host requirements

| Area | Requirement |
|---|---|
| OS | Linux (x86_64/arm64 where package support exists) or macOS |
| CPU | Hardware virtualization support recommended; 4+ cores recommended |
| RAM | 8 GB minimum; 16 GB+ recommended for instrumented workloads |
| Disk | 20 GB free minimum; 50 GB+ recommended for VM images and evidence |
| Runtime | Lima + QEMU |
| Languages | Go, Python 3, Ruby |
| Utilities | Git, Bash, curl |
| Agent | One selected primary terminal agent adapter |
| Network | Outbound access for initial installation/research enrichment as permitted by policy |

## Host configuration

Run `./scripts/prerequisites.sh` from the repository root. It repairs and verifies execute bits on repository shell scripts, configures `PATH`, `GOPATH` and `GOBIN`, and installs mandatory virtualization/runtime prerequisites.

For the full research profile:

```bash
CUSIMANSE_INSTALL_PRODUCTION_PROFILE=1 ./scripts/prerequisites.sh
```

For explicit observability setup:

```bash
CUSIMANSE_INSTALL_OBSERVABILITY=1 ./scripts/prerequisites.sh
```

The installer is intentionally fail-closed for observability products whose release-specific installation method is not verified. It must not guess package names or fetch arbitrary binaries.

## Agent observability and governance plane

Agent execution should emit OpenTelemetry traces/metrics/logs into the observability plane. Phoenix provides an OpenTelemetry-compatible research UI/backend. Numbat and Aegis are supported integration targets only when their verified adapters/installers are present.

```text
Primary Agent
     |
     | traces / metrics / logs
     v
OpenTelemetry SDK/exporters
     |
     +------> Phoenix (research observability)
     +------> Numbat (agent observability adapter)
     +------> Aegis (agent governance/observability adapter)
     |
     v
Evidence / audit plane
```

Observability and governance improve detection, tracing, auditability and operational control. They are **not** the VM security boundary.

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
