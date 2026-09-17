# ADK Go 2 Migration Plan

This branch is the native Go evolution path for Cusimanse. It is intentionally isolated from every other repository and branch.

## Completed in this increment

- Created `adk-cusimanse` from `main`.
- Raised the Go baseline to 1.25.
- Added official `google.golang.org/adk/v2` dependency.
- Added a native Go ADK agent package.
- Added a capability request tool that delegates to the existing Go capability registry and policy engine.
- Added ADK session and memory services for the development runtime.
- Added a durable atomic execution-state journal.
- Added a native `cusimanse-agent` terminal entry point.
- Added architecture and migration documentation.

## Next implementation increments

### 1. Graph-native research workflow

Build the research loop as an ADK 2 workflow graph with explicit nodes for contract interpretation, planning, capability execution, observation, analysis, verification and final reporting. Use graph routing and bounded retry/iteration semantics rather than a second orchestration framework.

### 2. Persistent session state

Replace the development in-memory session service with a persistent `session.Service` implementation where appropriate. Preserve the existing `internal/state` journal as the recovery/audit envelope.

### 3. Persistent artifacts and memory

Wire ADK artifact storage to the evidence lifecycle and provide a persistent memory implementation. Memory remains advisory; evidence remains authoritative.

### 4. Provider-neutral model layer

Add a model factory/adapter boundary so Gemini, OpenAI-compatible, Anthropic and local models can be selected without leaking provider concerns into capabilities or policy. Localhost LiteLLM/OmniRoute may be supported as transport adapters.

### 5. Capability surface

Expose stable typed capabilities for resolve, provision, instrument, execute, observe, collect, analyze, verify, preserve and destroy. Keep the capability registry framework-neutral so CLI, ADK and future adapters use the same authority.

### 6. Recovery and replay

Add tests for interruption before and after capability execution, duplicate requests, approval pauses, process restart, resume, evidence hashing and failed providers. Mutating operations must be idempotent or produce an explicit ambiguous-effect state.

### 7. Production single binary

Target a single Go binary with terminal operation, structured output, durable sessions, policy enforcement, capability providers and optional API/A2A surfaces. Development web tooling must never become the production security boundary.

## Non-goals

- No Python agent runtime in this branch.
- No LangGraph dependency.
- No Goose orchestration dependency.
- No parallel policy authority.
- No direct host execution from the LLM.
- No credentials embedded in prompts, recipes or evidence.

## Validation gate

A feature is considered production-ready only after deterministic tests demonstrate authorization, policy enforcement, recovery, evidence provenance and cleanup behavior.
