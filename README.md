# Cusimanse Agent Runtime (CAR)

**Cusimanse Agent Runtime (CAR)** is a declarative, policy-gated runtime for security research. A research contract describes *what* should be investigated; CAR validates the contract, turns it into a normalized intermediate representation (IR), plans dependencies, resolves capabilities, applies policy and approval, executes only through registered adapters, records observations and evidence, and controls disposable compute lifecycle.

An optional LLM reasoning layer uses **Vercel AI SDK 7** to propose the next declarative research intent. The model is never the execution authority.

> **The model proposes. CAR validates and authorizes. Adapters execute. Evidence preserves what happened.**

## Architecture

![CAR architecture](docs/architecture.svg)

The runtime authority boundary is:

```text
LLM
 └─ THINK / ANALYZE / PROPOSE

CAR
 └─ VALIDATE / COMPILE / PLAN / RESOLVE / AUTHORIZE /
    EXECUTE / OBSERVE / PRESERVE / VERIFY / DESTROY

Adapters
 └─ perform only operations authorized by CAR
```

A model proposal is data, not an instruction channel. It must re-enter the normal contract, planning, capability, policy, approval, and operation path before it can produce an effect.

## What CAR does

A typical research cycle is:

```text
Research YAML/JSON
       ↓
Contract validation + compilation
       ↓
Normalized CAR IR
       ↓
Deterministic dependency planning
       ↓
Capability resolution
       ↓
Policy / approval gate
       ↓
Operation engine
       ↓
Registered adapter
       ↓
Disposable compute / tool / API
       ↓
Observation + evidence collection
       ↓
Runtime state + provenance
       ↓
Optional LLM reasoning proposal
       ↺
```

CAR is deliberately separated into contracts, planning, authorization, execution adapters, evidence, and lifecycle control so that security-research workloads can be added without giving the reasoning model direct host or tool access.

## End-user quick start

The repository currently provides the runtime library and contracts. The command-line entry point is not yet part of this branch, so use the exported TypeScript APIs from an application or integration layer.

### 1. Install

Use Node.js 22 or newer and install the repository dependencies:

```bash
npm install
```

### 2. Define a research recipe

Example: `recipes/examples/npm-install.yaml`

```yaml
api_version: v1
kind: ExperimentRecipe
experiment_id: npm-install-example
description: Install a declared npm workload inside disposable research compute.
research_question:
  id: rq-npm-install
  question: What observable process, filesystem, and network behavior occurs during npm install?
scope:
  networks:
    - declared-test-network
  paths:
    - /workspace
  hosts:
    - disposable-vm
operation_kinds:
  - vm
  - tool
  - evidence
intents:
  - id: provision-research-vm
    capability: vm.create
    parameters:
      provider: lima
      profile: research-default
    depends_on: []
  - id: run-npm-install
    capability: workload.npm.install
    parameters:
      working_directory: /workspace
      package_manager: npm
    depends_on:
      - provision-research-vm
```

The recipe is declarative: it names research intent and parameters rather than embedding arbitrary shell commands.

### 3. Compile the recipe

The compiler accepts the parsed YAML/JSON object and produces normalized CAR IR:

```ts
import { compileRecipe } from "./src/compiler/index.js";

const ir = compileRecipe(recipe, {
  format: "yaml",
  path: "recipes/examples/npm-install.yaml",
});
```

The resulting IR contains the experiment identity, source provenance, capability intents, parameters, and normalized dependencies.

### 4. Run through CAR

Applications compose the runtime dependencies explicitly:

```ts
const result = await runtime.run(ir, state);
```

For disposable research, use `DisposableResearchWorkflow` with a `LimaLifecycle` and registered runtime dependencies. The workflow creates the declared VM, runs CAR, and destroys the VM in a `finally` block even if execution fails.

See [`docs/workflow.md`](docs/workflow.md) for the lifecycle contract and [`docs/runtime.md`](docs/runtime.md) for the orchestration sequence.

## What CAR generates

A CAR execution returns runtime state and a cycle result containing:

- **Runtime phase** — for example `planning`, `executing`, `observing`, `awaiting-approval`, or `completed`.
- **Operation records** — proposed, pending approval, running, succeeded, failed, or denied operations.
- **Runtime events** — append-only events describing proposals, approvals, operation outcomes, observations, and lifecycle events.
- **Observations** — runtime observations associated with an operation or source.
- **Evidence references** — evidence identity, SHA-256, byte size, URI, evidence kind, experiment provenance, optional operation provenance, and recording time.
- **Reasoning proposals** — when a reasoner is configured, a typed declarative proposal for a possible next research intent.

Example evidence record shape:

```json
{
  "id": "ev_...",
  "kind": "file",
  "uri": "evidence/npm-install.log",
  "sha256": "...",
  "size": 1234,
  "provenance": {
    "experimentId": "npm-install-example",
    "operationId": "op_...",
    "recordedAt": "2026-09-16T00:00:00.000Z"
  }
}
```

The evidence collector records evidence identity and provenance; durable artifact storage is intentionally an adapter/integration concern. See [`docs/evidence.md`](docs/evidence.md).

## Implementing a disposable research cycle

A concrete integration should implement the following boundaries:

1. **Recipe input** — parse YAML/JSON and pass the resulting object to `compileRecipe()`.
2. **Capability registry** — register only known capabilities and parameter validators.
3. **Policy engine** — define explicit allow, approval-required, and deny rules. Unmatched operations are denied by default.
4. **Operation engine** — keep operation state separate from adapter execution.
5. **Adapter registry** — map each approved capability to one concrete adapter.
6. **Lima provider** — implement VM create, command execution, and destruction behind `LimaProvider`.
7. **Workload adapters** — implement shell, file, process, and npm behavior against the intended disposable environment rather than the host.
8. **Evidence collector/storage** — collect observations and immutable evidence references, hash captured content, and persist artifacts using a controlled storage adapter.
9. **Workflow** — call `DisposableResearchWorkflow.run()`. VM destruction belongs in the workflow's guaranteed cleanup path.
10. **Optional reasoning** — add `VercelAIReasoner` only as a proposal source. Every proposal must be validated and authorized again before execution.

Conceptually:

```text
create VM
   ↓
execute authorized research operations
   ↓
collect observations
   ↓
hash + preserve evidence
   ↓
record provenance
   ↓
produce research result
   ↓
destroy VM
```

The important lifecycle property is that **evidence preservation happens before disposable compute is destroyed** and destruction occurs even when runtime execution throws.

## Repository structure

```text
Cusimanse/
├── schema/
│   └── cusimanse-agent-runtime.yaml   # LinkML contract schema
├── recipes/
│   └── examples/                      # Declarative research recipes
├── src/
│   ├── compiler/                      # Recipe validation + normalization
│   ├── ir/                            # Canonical runtime IR
│   ├── planner/                       # Dependency graph + deterministic plan
│   ├── capabilities/                  # Capability registration/resolution
│   ├── policy/                        # Policy decisions + approval state
│   ├── operations/                    # Operation lifecycle/state boundary
│   ├── adapters/                      # Adapter contracts + Lima/workloads
│   ├── evidence/                      # Evidence identity + provenance
│   ├── state/                         # Runtime state + event model
│   ├── llm/                           # Proposal-only AI SDK reasoning
│   └── runtime/                       # Orchestration + disposable workflow
├── tests/                             # Contract and runtime behavior tests
├── docs/                              # User and architecture guides
└── .github/workflows/                 # CAR CI workflow
```

## Guides

| Guide | Purpose |
|---|---|
| [`docs/architecture.svg`](docs/architecture.svg) | Visual CAR architecture and authority boundary |
| [`docs/runtime.md`](docs/runtime.md) | Runtime orchestration and execution sequence |
| [`docs/workflow.md`](docs/workflow.md) | Disposable research lifecycle |
| [`docs/evidence.md`](docs/evidence.md) | Evidence hashing and provenance |
| [`docs/llm.md`](docs/llm.md) | Vercel AI SDK 7 proposal-only reasoning |
| [`docs/adapters.md`](docs/adapters.md) | Adapter contract and registry model |
| [`docs/lima.md`](docs/lima.md) | Lima disposable compute boundary |
| [`docs/workloads.md`](docs/workloads.md) | Shell, file, process, and npm contracts |
| [`docs/operations.md`](docs/operations.md) | Operation lifecycle and authorization boundary |
| [`docs/policy.md`](docs/policy.md) | Policy and approval behavior |

## Safety model

CAR maintains a strict authority boundary:

- LLM output is typed declarative data, not executable authority.
- Policy defaults to deny when no rule matches.
- Approval-required operations do not reach adapters until explicitly approved.
- Adapters receive authorized operations rather than raw recipes.
- Disposable compute is lifecycle-controlled by CAR's workflow boundary.
- Evidence is identified with cryptographic hashes and provenance metadata.
- The runtime does not turn arbitrary recipe text directly into host shell commands.

## Project status

This branch is the **agentic-runtime** implementation of CAR. It contains the core contract, IR, planner, capability, policy, operation, adapter, evidence, reasoning, orchestration, and disposable-workflow foundations. A production CLI, concrete Lima provider, durable evidence store, and additional research adapters can be layered on top of these contracts.
