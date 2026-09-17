# Cusimanse ADK Go 2 Architecture

## Purpose

`adk-cusimanse` evolves Cusimanse into a single native Go security research agent. Google ADK Go 2 supplies agent orchestration, model interaction, workflow execution, tool calling, HITL, session state, artifacts and memory primitives. Cusimanse remains the security authority for contracts, capabilities, policy, authorization, evidence and execution boundaries.

## Authority boundary

```text
Researcher / CLI
      |
      v
ADK Go 2 Agent Runtime
  - reasoning
  - planning
  - research loop
  - workflow graph
  - tool calls
  - HITL
  - session state
  - memory / artifacts
      |
      | capability request
      v
Cusimanse Go Authority
  - contract validation
  - requirement resolution
  - capability registry
  - policy / approval
  - execution constraints
  - evidence / provenance
      |
      v
Disposable execution backends
  - Lima / QEMU
  - Docker
  - other explicitly registered providers
```

**ADK may propose an action; it cannot authorize an action.** Every mutating capability must pass the Cusimanse policy boundary.

## Research loop

The agent follows a bounded loop:

`understand -> plan -> request capability -> execute -> observe -> analyze -> verify -> refine or finish`

The loop is stateful. ADK session state carries invocation/workflow state, while the Cusimanse durable journal records crash-recovery metadata and terminal status. Future persistent ADK `session.Service` implementations can replace the development in-memory service without changing capability or policy interfaces.

## Memory model

The runtime uses ADK's `memory.Service` abstraction. The first implementation uses `memory.InMemoryService()` for development and testing. Memory is deliberately separate from authoritative evidence: memories can guide future reasoning, but evidence must come from registered capabilities and preserved artifacts.

Use state scopes intentionally:

- session state: current research run and workflow progress;
- user state: durable researcher preferences when a persistent session backend is configured;
- app state: shared runtime configuration;
- temporary state: invocation-only values;
- ADK memory: searchable long-term conversational/research context;
- Cusimanse evidence: authoritative observations and findings.

## Durable execution

ADK workflow state is namespaced in session state. The `internal/state` package adds an atomic JSON snapshot for the Cusimanse execution envelope so process termination does not erase the last known phase. Production hardening should provide a persistent ADK `session.Service` and persistent artifact/memory services where supported.

## Provider strategy

The first branch uses the official ADK Gemini model adapter. Model selection is kept behind the agent construction boundary so additional ADK-compatible model adapters can be introduced without changing the capability API, policy engine or evidence model.

## Skills and capabilities

Capabilities are executable authority. Skills are research knowledge and operating guidance. A skill can explain how to investigate a behavior; only a registered capability can perform an operation. This prevents prompt content from becoming execution authority.

## HITL

ADK tool confirmation is enabled for capability requests. Cusimanse policy remains the second, authoritative gate. Approval must never be inferred from model text.

## Evidence

The agent must distinguish:

1. model reasoning;
2. tool/capability results;
3. observed telemetry;
4. preserved evidence;
5. independently verified findings.

Only the latter three categories can support a security finding. Evidence should be hashed and preserved before disposable compute is destroyed.

## Evolution path

1. Native ADK Go 2 agent and capability bridge.
2. Graph-based research workflow with explicit planner/researcher/analyzer/verifier nodes.
3. Persistent ADK session and artifact services.
4. Provider-neutral model factory and localhost gateway support.
5. Durable replay/resume tests and deterministic evidence verification.
6. Production single-binary agent with Lima/QEMU and other capability providers.

The branch intentionally avoids reintroducing a second agent framework or a competing execution authority.
