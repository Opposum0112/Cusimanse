# Cusimanse Production Architecture

## Purpose

This document describes the stateful, self-learning security-research architecture while preserving the Cusimanse security boundary and terminal-first primary-agent model.

## Layered model

```text
Campaign semantics
  YAML recipes / Taskflow-style tasks
          |
          v
Stateful execution
  LangGraph (runtime/checkpoints, not evidence authority)
          |
          v
Primary operator
  Goose | OpenCode | Grok | Antigravity | Pi | Hermes | Codex | Prime | Claude Code | Devin
          |
          v
Security experiment
  Cusimanse -> Lima/QEMU -> VM/OS controls
          |
          v
Evidence
  raw artifacts + telemetry + audit + verification
          |
          v
Durable case/evidence store
  artifact identity + findings + provenance + execution relations
          |
          v
Voyager-style learning
  retrieve -> execute -> evaluate -> refine -> verify -> promote
          |
          v
Skill package
  SKILL.md + scripts + references + eval/
          |
          +---------------------> future retrieval
```

## Responsibilities

| Layer | Responsibility | Security authority |
|---|---|---|
| YAML recipe | Campaign intent, tasks, roles, gates | No |
| Taskflow-style semantics | Reusable task sequencing patterns | No |
| LangGraph | Stateful execution, retries, HITL checkpoints | No |
| Agent adapter | Terminal operation and research actions | No |
| Lima/QEMU/VM/OS | Isolation, mounts, credentials, privilege and network enforcement | **Yes** |
| Evidence store | Durable facts and provenance | Evidence authority |
| Skill library | Reusable validated capabilities | No |
| policyctl | Host-side policy/configuration and token observability | Policy signal, not enforcement |
| MCP | Scoped tool access and enrichment | No |

## Security policy boundary

`policyctl` is a host-side policy/configuration and observability component that operates outside the experiment VM. It can report and configure policy signals, but it does not enforce the VM boundary. Lima/QEMU and the VM/OS controls enforce isolation, mounts, credentials, privilege and network policy. Agents, skills, MCP servers and orchestration layers cannot replace or bypass that boundary.

## Taskflow position

GitHub Security Lab Taskflow is treated as a recipe/taskflow reference, not as the Cusimanse security controller. Its YAML-oriented task sequencing, agent handoffs, reusable prompts and conditional task concepts are useful for campaign recipes. Cusimanse remains responsible for experiment semantics, evidence, approval and the VM boundary.

## Learning position

Prime Agent and Hermes are optional self-improving primary-agent adapters. A Voyager-style loop is the learning pattern around them. A successful agent interaction does not automatically become a trusted skill. Promotion requires provenance, replay, independent verification and approval.

## Skill lifecycle

```text
Artifact / observation
        |
        v
Skill candidate
        |
        v
Static review + capability manifest
        |
        v
Replay on distinct artifact(s)
        |
        v
Independent verification
        |
        v
Human approval
        |
        v
Versioned validated skill
        |
        v
Indexed retrieval
```

## Evidence relation model

The durable store should represent:

```text
Artifact -> Finding
Artifact -> SkillCandidate
Skill -> Execution -> Artifact
Execution -> Verification
Skill -> validated_on / failed_on / derived_from
```

This is separate from the LangGraph checkpoint store. LangGraph answers “where is the workflow?”; the evidence store answers “what happened and why is this skill trusted?”.

## Primary self-learning adapter contract

Prime Agent and Hermes adapters expose the same logical contract:

1. Load the shared experiment contract.
2. Load the selected campaign recipe.
3. Retrieve candidate skills using task/artifact metadata.
4. Present candidates as capabilities, not authority.
5. Operate only inside the approved experiment boundary.
6. Capture tool traces and outputs.
7. Emit evidence and a skill candidate when a reusable procedure is discovered.
8. Run evaluation/replay.
9. Request promotion approval; never self-promote privileged or high-risk skills.

Agent-native memory, skills and subagents remain agent capabilities. Cusimanse provenance and promotion controls remain authoritative for learned skills.

## Security invariants

- The agent is not the sandbox.
- A prompt, skill, MCP server or vector index is not a security boundary.
- Generated code is untrusted until reviewed and executed under the experiment boundary.
- Credentials never enter skill source or MCP arguments.
- Evidence is preserved and hashed before VM destruction.
- Missing integrations are `NOT_DEPLOYED`.
- AI assertions are not evidence.

## Compatibility strategy

The architecture is additive. Existing Goose recipes and `go-install-001` remain the compatibility baseline. New campaign/learning components consume the same experiment contracts and can be disabled without affecting the existing operator path.
