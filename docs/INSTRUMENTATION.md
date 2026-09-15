# Instrumentation

Instrumentation is a **guest-side capability** of the disposable research environment. It is declared once in `recipes/instrumentation/security-research.yaml`, provisioned by the Lima guest recipe, and operated by the Go runtime/agent workflow. It is not an additional host authority layer.

## Instrumentation inventory

| Class | Tools | Observation |
|---|---|---|
| Process | `ps`, `pgrep`, `lsof` | process inventory, ancestry and open resources |
| Syscall | `strace` | syscall activity and process behavior |
| Network | `ss`, `ip`, `tcpdump` | sockets, interfaces and packet capture |
| DNS | `dig`, `getent` | name-resolution behavior |
| Filesystem | `find`, `stat`, `sha256sum`, `inotifywait`, `file` | files, metadata, hashes and filesystem events |
| Security/runtime | `dmesg`, `journalctl` | kernel and service events |
| Optional eBPF | `bpftrace` | deeper kernel/runtime observation when available |

## Installation

The instrumentation packages are installed in the disposable Linux guest by `recipes/lima/security-research.yaml`. The host installer provides Lima/QEMU and the control-plane prerequisites; it should not be treated as the execution environment for the reference workload.

The reference guest provisioning installs the required package set before the workload starts. Collectors are required to start before the workload so that evidence is not lost during initialization.

## Runtime access

Researchers normally do **not** enter the guest or start collectors manually. The normal path is:

```bash
cusimanse validate
cusimanse preflight
cusimanse resolve npm-threat-001
cusimanse --approved run npm-threat-001 <session-id>
```

For a troubleshooting or smoke-test session, direct Lima access is available, but it is an operator diagnostic path rather than the normal execution interface:

```bash
limactl validate recipes/lima/security-research.yaml
limactl start --name=cusimanse-smoke recipes/lima/security-research.yaml
limactl shell cusimanse-smoke -- bash -lc 'ps --version; strace -V; tcpdump --version; ss --version || true'
limactl delete --force cusimanse-smoke
```

The agent and Go runtime own the normal VM lifecycle. Direct `limactl` use must remain within the declared recipe and policy boundary.

## Evidence rules

- Collectors start before the workload.
- Raw evidence is immutable after collection.
- Hashes and provenance are generated before destruction.
- Model output is analysis, not raw evidence.
- Missing optional instrumentation is recorded as partial capability rather than silently substituted.

The authoritative profile is `recipes/instrumentation/security-research.yaml`; this document is the researcher-facing explanation of that profile.
