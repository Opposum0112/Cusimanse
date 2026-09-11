# 01 — Deployment Architecture

![Cusimanse deployment architecture](docs/images/cusimanse-deployment-architecture.svg)

> **Deployment view:** shared experiment contracts and agent adapters drive controlled workloads inside disposable Lima/QEMU VMs; instrumentation, evidence handling and verification remain inside the research lifecycle.

## Project model

```text
Human / CI intent
        ↓
Markdown research contract
        ↓
Goose project entry recipe
        ↓
Agent adapter
  Goose | OpenCode | Grok Build | Antigravity | future
        ↓
Modular recipes + policyctl + MCP + skills + audit
        ↓
Disposable Lima / QEMU VM
        ↓
Workload + instrumentation + monitoring
        ↓
Evidence → reduction → forensics → independent verification
        ↓
Report → evidence preservation → VM destruction
```

## Deployment layers

| Layer | Responsibility | Security significance |
|---|---|---|
| Human / CI | Defines intent, scope and authorization | Human authorization remains authoritative |
| Shared contract | Specifies experiment semantics and required evidence | Prevents adapter-specific drift |
| Agent adapters | Operate the shared contract through provider-specific tooling | Must not bypass approvals or policy |
| Recipes / registries | Compose experiments, tools, MCP, skills and audit | Configuration layer, not a security boundary |
| `policyctl` | Configures host/security policy and token dashboard | Policy decision only; not enforcement |
| Lima / QEMU VM | Runs the disposable research environment | Primary workload isolation boundary |
| Instrumentation | Captures process, filesystem, network and runtime signals | Starts before target execution |
| Evidence pipeline | Preserves, reduces, analyzes and verifies artifacts | Evidence is the basis for claims |
| Report / destroy | Produces findings, preserves evidence, destroys VM | Limits workload persistence |

## Boundaries

1. **Goose** is the maintained reference project operator/executor.
2. **Agent adapters** translate the shared contracts into the selected agent's tools, MCP and execution model.
3. **Recipes** are the configuration and composition layer; they remain provider-neutral except for adapter entry recipes.
4. **MCP** exposes only registry-approved capabilities.
5. **Skills** provide reviewed instructions but never grant privilege.
6. **Audit** records requested, approved, executed and observed actions.
7. **policyctl** configures host/security policy and owns the local token dashboard only.
8. **Lima/QEMU** provide disposable workload isolation.
9. **Evidence** is preserved and hashed before destruction, then important findings are independently verified.

## Operator and adapter separation

The project contract defines **what** must happen and the evidence required to claim success. The selected adapter determines **how** the agent reasons and performs approved operations.

```text
Shared contract
      |
      +---- Goose reference adapter
      +---- OpenCode adapter
      +---- Grok Build adapter
      +---- Antigravity adapter
      +---- future adapter
      |
      v
Same experiment semantics
```

An adapter must not bypass `policyctl`, approval gates, audit requirements or evidence preservation. AI output is advisory; the VM/OS and host controls are the actual security enforcement boundary.

## Deployment lifecycle

```text
DISCOVER → VALIDATE → PREFLIGHT → INSTALL → PLAN → REVIEW → APPROVE
    ↓
PROVISION VM → START INSTRUMENTATION → EXECUTE WORKLOAD
    ↓
COLLECT → REDUCE → FORENSICS → INDEPENDENT VERIFICATION
    ↓
REPORT → HASH/PRESERVE EVIDENCE → DESTROY VM
```

## Security boundary rule

The diagram intentionally separates **policy and agent logic** from the **VM/OS enforcement boundary**. Prompts, skills, MCP servers, adapters and `policyctl` must never be treated as containment mechanisms. Isolation depends on VM configuration, filesystem/mount controls, credential separation, network controls and explicit approval gates.

## Design principle

> **Markdown specifies. YAML configures. Agent adapters operate. Policy constrains. Audit records. Evidence proves.**
