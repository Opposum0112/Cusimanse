# 02 — System Requirements

![Architecture](ai-security-lab-architecture.png)

## Baseline

| Requirement | Baseline |
|---|---|
| Architecture | x86_64 baseline |
| RAM | 16 GB recommended for the reference lab |
| Free disk | 50 GB minimum; 100–200 GB preferred |
| Virtualization | QEMU acceleration where available |
| Host tools | Git, Bash, Python 3, QEMU, Lima |
| Data tools | jq, yq, ripgrep, Miller |

## Required before project execution

Goose must be installed/configured. The installation recipe then checks the host for QEMU, Lima, Git, shell/runtime requirements and resource headroom.

## Optional tools

Security collectors such as `strace`, `lsof`, `bpftrace`, `tcpdump`, Zeek, Suricata and Numbat are selected by the active experiment. Do not install the whole stack just to start the project.

## Host boundary

Management services bind to `127.0.0.1` by default. MCP servers, model gateways and observability endpoints must not be exposed publicly unless a recipe explicitly requires it.

## Preflight

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=02
```

A failed prerequisite stops the section with `NOT_DEPLOYED`.
