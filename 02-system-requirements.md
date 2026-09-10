# 02 — System Requirements

## Host hardware

| Requirement | Baseline |
|---|---|
| CPU | Intel x86_64 |
| Host | MacBook Pro A1278 |
| RAM | 16 GB |
| Free disk | 50 GB minimum |
| Recommended free disk | 100–200 GB |
| Virtualization | Intel VT-x |
| Host OS | Parrot OS |
| Network | Stable Internet connection |

## Recommended resource budget

| Component | Typical budget |
|---|---:|
| Parrot desktop | 3–4 GB |
| Agents / CLI processes | 0.5–1.5 GB |
| Gateway + policy + observability | 1–2 GB |
| One active Lima VM | 2–4 GB |
| Reserve | 4–6 GB |

This is a starting budget, not a hard allocation.

## Required host software

- Git
- curl/wget
- Python 3
- Go
- Node/npm where required by selected tools
- QEMU
- Lima
- Docker OR Podman
- standard build tools
- jq
- yq
- ripgrep
- Miller

## Security tooling

Install incrementally and verify each tool:

- strace
- lsof
- bpftrace
- BCC
- Tetragon
- Sysdig
- tcpdump
- tshark
- Zeek
- Suricata
- mitmproxy

Not every tool must be active simultaneously.

## VM requirements

Lima should use QEMU on this Linux host.

Initial VM policy:
- 2–4 vCPU
- 2–4 GB RAM
- disposable root disk
- minimal host mounts
- no host credential mounts
- controlled networking
- evidence exported before destruction

## Network requirements

Management endpoints should bind to `127.0.0.1` unless remote access is explicitly required.

Do not expose model gateways, observability dashboards, policy services, or MCP servers publicly by default.

## Validation

Before deployment, verify:

```bash
uname -m
uname -r
nproc
free -h
df -h
qemu-system-x86_64 --version
limactl --version
git --version
jq --version
yq --version
```

For virtualization acceleration, inspect the host's KVM capability before depending on accelerated QEMU.
