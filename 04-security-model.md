# 04 — Security Model

![Architecture](docs/images/ai-security-lab-architecture.svg)

## Threat model

Agents may encounter prompt injection, malicious repositories, unsafe commands, compromised dependencies, secret exposure or excessive tool permissions. Workloads may download code, execute build hooks, modify files and make network connections.

## Security boundaries

```text
Agent adapter
  ↓
Skills + tools + MCP registry
  ↓
Policy + audit decision
  ↓
Approval
  ↓
Disposable Lima/QEMU VM
  ↓
Instrumentation + evidence
  ↓
Reference enrichment
  ↓
Independent verification
```

Skills, MCP servers, prompts and policy decisions are coordination/capability layers. They do not replace the VM/OS enforcement boundary.

## Non-negotiable controls

| Control | Default |
|---|---|
| Host credentials in VM | deny |
| Unrestricted host mounts | deny |
| Unknown installers | deny |
| Public MCP exposure | deny |
| Unknown skill/server | `NOT_DEPLOYED` |
| Public reference submission of private data | deny |
| Privileged/destructive actions | approval-required |
| Evidence before VM deletion | required |
| Independent verification | required |
| Missing capability | `NOT_DEPLOYED` |

## Skills

Skills are reviewed instructions selected from `recipes/skills/registry.yaml`. They cover planning, triage, static and dynamic analysis, network analysis, malware analysis, reverse engineering, threat intelligence, vulnerability research, dependency analysis, detection engineering, forensics, IOC extraction, ATT&CK mapping, evidence reduction and independent verification.

Skills cannot grant privileges. Material selection and use is audited.

## MCP

MCP servers are registry-approved capabilities defined in `recipes/mcp/registry.yaml`. Read-only public reference integrations may enrich research, while VM control, writes and privileged actions require approval. Public exposure is denied by default. Secrets are never passed through MCP arguments.

## Reference databases

`recipes/reference/security-research-databases.yaml` catalogs authoritative and community research sources including MITRE ATT&CK, NVD/CVE, CISA KEV, OWASP, Sigma, YARA, Suricata and selected IOC/malware enrichment services.

Reference data is **enrichment, not evidence**. Every external result requires source provenance and retrieval time. Important findings require independent verification. Private workload data must not be submitted to public reference services.

## Audit

Every material action records requested, approved, executed and observed states. Secrets are excluded; sensitive arguments are hashed.
