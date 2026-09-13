# Cusimanse Production Architecture

## Purpose

Cusimanse is a **declarative, agentic, pluggable security-research platform**. Markdown contracts specify research semantics and acceptance; YAML recipes configure modular components; exactly one selected primary agent adapter operates and executes the case; optional CrewAI roles provide specialist coordination; and the blackboard preserves the complete evidence-led case record.

## Canonical architecture

The single authoritative visual architecture is `docs/architecture/cusimanse-architecture.svg`; the equivalent Mermaid flow is `docs/architecture/cusimanse-architecture.mmd`.

```text
Markdown contract
  ↓
YAML recipe graph
  ↓
Selected primary agent adapter
  ├─ optional specialist roles / CrewAI
  ├─ versioned skills
  └─ scoped MCP
  ↓
Plan → Review → Approve → Provision → Instrument → Execute
  ↓
Collect → Analyze → Verify → Report → Preserve → Destroy
  ↓
Blackboard / durable case
  ├─ run + audit records
  ├─ raw evidence + telemetry
  ├─ findings + provenance + verification
  └─ technical research report
  ↓
Self-learning / promotion
  → candidate → review → replay → independent verify → human approval → validated skill
  ↺ skill retrieval
```

## Responsibility boundaries

| Plane | Responsibility | Authority |
|---|---|---|
| Markdown contracts | Intent, scope, hypotheses, acceptance, safety and evidence requirements | Semantics |
| YAML recipes | Component composition and configuration | Configuration |
| Agent adapter | Translate a native agent shell into the common contract | Operator/executor |
| CrewAI role plane | Optional specialist role coordination | No security authority |
| Skills | Reusable research procedures and capabilities | No privilege authority |
| MCP | Scoped tool/integration access | No privilege authority |
| Blackboard | Durable runs, audit, evidence, findings, provenance, verification and report inputs | Evidence authority |
| Learning plane | Candidate generation, evaluation, replay and promotion | Human-gated |
| policyctl | Host-side policy/configuration and observability signal | Outside agent control plane |
| Lima/QEMU + VM/OS | Isolation, mounts, credentials, privilege and network enforcement | **Security boundary** |

## Agent and campaign self-learning

Agents and campaigns may propose improvements from completed evidence. They do not mutate the immutable base contract at runtime.

```text
case evidence
  → candidate skill / recipe improvement
  → capability + provenance review
  → evaluation
  → replay on distinct artifact(s)
  → independent verification
  → human approval
  → versioned validated skill
  → indexed retrieval
```

A candidate is never trusted merely because an agent generated it or retrieval ranked it highly. Failed candidates and evaluation evidence remain part of the case record.

## Blackboard and research report

The blackboard is the durable research workspace and evidence index, not merely a message bus. A case should relate:

```text
Case
 ├─ Campaign
 ├─ Execution / Run
 │   ├─ Audit events
 │   ├─ Tool traces
 │   └─ Runtime telemetry
 ├─ Artifacts
 │   ├─ raw evidence
 │   ├─ hashes / manifest
 │   └─ provenance
 ├─ Findings
 │   └─ independent verification
 ├─ Skill candidates / validation history
 └─ Research report
     ├─ hypothesis and method
     ├─ environment and workload
     ├─ technical observations
     ├─ evidence references
     ├─ analysis and conclusions
     └─ verification / limitations
```

The report must reference preserved evidence. Model output alone is never evidence.

## Runtime state versus evidence

A stateful runtime such as LangGraph may checkpoint workflow position, retries and HITL state. It is not the evidence authority. The blackboard/durable case store answers **what happened, what evidence supports it, and why a result or skill is trusted**.

## Pluggable role and skill plane

`recipes/orchestration/role-skill-plugin.yaml` defines a provider-neutral contract. A role can declare the skills, tools and MCP capabilities it needs and returns structured results. The selected primary agent remains the sole case operator/executor.

CrewAI is one optional implementation of this role plane. Replacing it must not change experiment semantics, evidence requirements or the security boundary.

## Security policy boundary

`policyctl` is deliberately **outside the agent control plane**. It provides host-side policy/configuration and token-observability signals. It is not the sandbox and does not replace VM enforcement.

Lima/QEMU and VM/OS controls enforce the actual boundary: filesystem/mount controls, credentials, privilege and network restrictions. No agent, role, skill, MCP server, orchestration framework, prompt or retrieval index may bypass or redefine that boundary.

## Compatibility

Existing Goose recipes and `experiments/go-install-001` remain the reference compatibility path. Other adapters consume the same contracts through the adapter layer. Optional roles, skills, MCP integrations and learning components can be unavailable without silently changing the experiment semantics; the explicit state is `NOT_DEPLOYED`.
