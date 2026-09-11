# 01 — Deployment Architecture

![Project architecture](docs/images/ai-security-lab-project-architecture.svg)

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

## Design principle

> **Markdown specifies. YAML configures. Agent adapters operate. Policy constrains. Audit records. Evidence proves.**
