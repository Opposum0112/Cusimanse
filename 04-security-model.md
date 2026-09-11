# 04 — Security Model

![Architecture](docs/images/ai-security-lab-architecture.svg)

## Threat model

Agents may encounter prompt injection, malicious repositories, unsafe commands, compromised dependencies, secret exposure or excessive tool permissions. Workloads may download code, execute build hooks, modify files and make network connections.

## Security boundaries

```text
Goose
  ↓
MCP / Skills
  ↓
Audit + policy decision
  ↓
Approval
  ↓
Disposable Lima/QEMU VM
  ↓
Instrumentation + evidence
  ↓
Independent verification
```

## Non-negotiable controls

| Control | Default |
|---|---|
| Host credentials in VM | deny |
| Unrestricted host mounts | deny |
| Unknown installers | deny |
| Public MCP exposure | deny |
| Privileged/destructive actions | approval-required |
| Evidence before VM deletion | required |
| Independent verification | required |
| Missing capability | `NOT_DEPLOYED` |

## MCP and skills

MCP servers are registry-approved capabilities. Skills are reviewed instructions. Neither replaces the VM boundary or policy controls.

## Audit

Every material action records requested, approved, executed and observed states. Secrets are excluded; sensitive arguments are hashed.
