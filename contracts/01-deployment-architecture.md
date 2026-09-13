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

Host `scripts/*.sh` are deliberately limited to prerequisite installation, adapter selection, configuration, validation and preflight. They must not become a second lifecycle controller. `policyctl` configures policy and token accounting; it does not enforce VM isolation.

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

## Primary agent shell and adapters

The common contract defines **what** must happen. The selected adapter defines **how** that provider's shell performs the approved actions.

```text
Shared YAML contracts
        ↓
Primary agent shell
        ↓
+-------------------------------+
| Goose | OpenCode | Grok |      |
| Antigravity | Pi | Hermes |    |
| Codex | Prime Agent |          |
| Claude Code | Devin            |
+-------------------------------+
        ↓
Same experiment semantics
        ↓
Lima / QEMU enforcement boundary
```

Native shell entry points are adapter-specific. The current contract records intended forms; preflight must verify the installed command and supported invocation before runtime acceptance.

## Deployment lifecycle

```text
BOOTSTRAP
  scripts/prerequisites.sh
        ↓
PREFLIGHT / VALIDATE
  scripts/agent-preflight.sh
  policyctl validate
  scripts/tests/validate-project.sh
        ↓
PRIMARY AGENT SHELL
  load YAML → plan → review → approve
        ↓
COMPUTE LIFECYCLE
  provision → instrument → execute → collect
        ↓
EVIDENCE LIFECYCLE
  reduce → forensics → independent verify → report
        ↓
PRESERVE → HASH → DESTROY
```

The reference runtime test is `experiments/go-install-001`. Adapter equivalence means executing that same semantic contract through different native shells and comparing evidence, audit records, findings and verification—not merely comparing textual agent output.

## Evidence-bounded learning

Learning runs through the same primary shell but cannot rewrite the security boundary:

```text
observe → compare → propose → validate → independently verify
→ human approve → promote → checkpoint / rollback
```

Only reviewed, non-security improvements may be promoted. VM isolation, credentials, privileges, network allowlists, approval requirements and evidence-integrity controls remain outside the model's authority.

## Boundaries

1. The selected primary agent shell owns orchestration, execution and lifecycle coordination.
2. Adapters provide provider-specific shell/tool integration while preserving shared semantics.
3. Recipes are configuration/composition, not enforcement.
4. MCP exposes only registry-approved capabilities.
5. Skills provide reviewed instructions and never grant privilege.
6. Audit records requested, approved, executed and observed actions.
7. `policyctl` configures host/security policy and token accounting; it is not a sandbox.
8. Lima/QEMU and VM/OS controls provide workload isolation.
9. Evidence is preserved and hashed before destruction; important findings require independent verification.

## Security boundary rule

Prompts, models, skills, MCP servers, adapters, CrewAI and `policyctl` must never be treated as containment mechanisms. Isolation depends on VM configuration, filesystem/mount controls, credential separation, network controls and explicit approval gates.

## Design principle

> **Markdown specifies. YAML configures. The primary agent shell operates and orchestrates. Adapters translate. Policy constrains. Audit records. Evidence proves. VM/OS controls contain.**
