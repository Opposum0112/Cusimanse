# 01 — Deployment Architecture

![Cusimanse deployment architecture](../docs/images/cusimanse-architecture.svg)

> **Deployment view:** declarative research contracts are operated by one selected primary agent shell; disposable Lima/QEMU VMs provide the security boundary; instrumentation and evidence handling remain part of the same agent-driven research lifecycle.

## Project model

```text
Human / CI intent
        ↓
Markdown research contract + YAML recipes
        ↓
SELECTED PRIMARY AGENT SHELL
        ↓
Discover → Validate → Preflight → Plan → Review → Approve
        ↓
Provision compute → Instrument → Execute → Collect
        ↓
Reduce → Forensics → Independent verification → Report
        ↓
Preserve evidence → Destroy compute
```

### Terminal-first rule

Cusimanse is **agent-shell driven**. Once bootstrap and preflight are complete, the selected primary agent shell is the authoritative operator interface for the complete operator, execution and orchestration cycle.

Host `scripts/*.sh` are limited to prerequisite installation, adapter selection, configuration, validation and preflight. They must not become a second lifecycle controller. `policyctl` configures policy and token accounting; it does not enforce VM isolation.

## Deployment layers

| Layer | Responsibility | Security significance |
|---|---|---|
| Human / CI | Defines intent, scope and authorization | Human authorization remains authoritative |
| Shared contract | Specifies experiment semantics and required evidence | Prevents adapter-specific drift |
| Primary agent shell | Plans, orchestrates and executes approved lifecycle actions | Operator only; not the containment boundary |
| Agent adapter | Maps shared contract to provider-native shell/tooling | Must not bypass approvals or policy |
| Recipes / registries | Compose experiments, tools, MCP, skills and audit | Configuration layer, not a security boundary |
| `policyctl` | Configures host/security policy and token dashboard | Policy decision/configuration only |
| Lima / QEMU VM | Runs disposable research environment | **Primary workload isolation boundary** |
| Instrumentation | Captures process, syscall, network, filesystem and runtime signals | Starts before target execution |
| Evidence pipeline | Preserves, reduces, analyzes and verifies artifacts | Evidence is the basis for claims |
| Report / destroy | Produces findings, preserves evidence and destroys compute | Limits workload persistence |

## Lifecycle

```text
BOOTSTRAP → PREFLIGHT / VALIDATE → PRIMARY AGENT SHELL
→ APPROVAL → PROVISION → INSTRUMENT → EXECUTE → COLLECT
→ REDUCE → FORENSICS → INDEPENDENT VERIFY → REPORT
→ PRESERVE → HASH → DESTROY
```

The reference runtime test is `experiments/go-install-001`. Adapter equivalence means executing the same semantic contract through different native shells and comparing evidence, audit records, findings and verification—not merely textual output.

## Evidence-bounded learning

```text
observe → compare → propose → validate → independently verify
→ human approve → promote → checkpoint / rollback
```

Only reviewed, non-security improvements may be promoted. VM isolation, credentials, privileges, network allowlists, approval requirements and evidence-integrity controls remain outside model authority.

## Security boundary rule

Prompts, models, skills, MCP servers, adapters, CrewAI and `policyctl` are not containment mechanisms. Isolation depends on VM configuration, filesystem/mount controls, credential separation, network controls and explicit approval gates.

> **Markdown specifies. YAML configures. The primary agent operates and orchestrates. Adapters translate. Policy constrains. Audit records. Evidence proves. VM/OS controls contain.**
