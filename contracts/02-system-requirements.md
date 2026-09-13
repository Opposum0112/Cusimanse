# 02 — System Requirements

![Architecture](../docs/images/cusimanse-architecture.png)

## Baseline

| Requirement | Baseline |
|---|---|
| Architecture | x86_64 is the tested baseline. arm64 hosts may work if QEMU/Lima and `qemu-system-x86_64` (or an explicit arm64 compute profile) are installed; treat that as `PARTIAL` until evidenced. |
| RAM | 16 GB recommended for the reference lab |
| Free disk | 50 GB minimum; 100–200 GB preferred |
| Virtualization | QEMU acceleration where available |
| Host tools | Git, Bash, Python 3, Go 1.23+, QEMU, Lima, Goose CLI |
| Policy CLI | `./policyctl` built from `cmd/policyctl` |
| Data tools | `jq`, `yq`, `ripgrep` (and Miller where used) are experiment-selected; missing tools are `NOT_DEPLOYED`, not installed by `prerequisites.sh` |

## Required before project execution

1. Run `./scripts/install.sh` from the repository root (packages + `policyctl`).
2. Install and configure Goose **outside this repository**: CLI on `PATH`, model/provider settings, and any API key in the user environment — never in git.
3. `source ./scripts/goose-env.sh` in the shell that will run Goose.

The installation recipe then checks the host for QEMU, Lima, Git, shell/runtime requirements and resource headroom.

## Optional tools

Security collectors such as `strace`, `lsof`, `bpftrace`, `tcpdump`, Zeek, Suricata and Numbat are selected by the active experiment. Do not install the whole stack just to start the project.

## Host boundary

Management services bind to `127.0.0.1` by default. MCP servers, model gateways and observability endpoints must not be exposed publicly unless a recipe explicitly requires it.

## Preflight

Host-only checks (no compute):

```bash
./scripts/install.sh
source ./scripts/goose-env.sh
bash ./scripts/tests/validate-project.sh
```

Full reference lifecycle (creates disposable Lima/QEMU compute when Goose and policy allow it):

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

A failed prerequisite stops the run with `NOT_DEPLOYED`. Contract chapter numbers are not Goose `section` values.
