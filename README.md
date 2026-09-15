# Cusimanse Agent Runtime (CAR)

CAR is an LLM-augmented, domain-specific runtime for security-research contracts. It reads LinkML-governed YAML or JSON, builds a normalized IR, resolves registered capabilities, optionally asks an LLM to propose the next intents, then runs a policy gate before any adapter touches a tool, API, shell, or VM using Vercel AI SDK 7.

**The model proposes. CAR validates and authorizes. Adapters execute.**

## Commit 2 — Contract and semantic compiler

The declarative contract boundary and deterministic compilation path are established:

```text
LinkML-governed YAML / JSON
          ↓
   Contract validation
          ↓
     Semantic compiler
          ↓
      Cusimanse IR
```

## Commit 3 — Research state and event model

CAR now maintains runtime-owned materialized research state plus append-only event history. State captures experiment phase, active intent, operations, observations, and evidence references. Events record lifecycle and execution facts without granting authority to the reasoning layer.

## Commit 4 — Deterministic planner and dependency graph

The planner validates the IR dependency graph, rejects duplicate IDs, missing dependencies, self-dependencies, and cycles, then produces a deterministic topological execution order. Independent nodes are sorted lexicographically so planning is repeatable. The planner also exposes ready intents from a completed-intent set.

```text
Cusimanse IR
      ↓
Dependency Graph
      ↓
Deterministic Plan
      ↓
Ready Intents
```

Planning is side-effect free and does not resolve capabilities, authorize operations, execute adapters, or allow an LLM to choose execution order.

## Repository layout

```text
Cusimanse/
├── README.md
├── package.json
├── tsconfig.json
├── schema/
│   └── cusimanse-agent-runtime.yaml
├── recipes/
│   └── examples/
├── src/
│   ├── compiler/
│   ├── ir/
│   ├── state/
│   ├── planner/
│   ├── capabilities/
│   ├── policy/
│   ├── operations/
│   ├── adapters/
│   ├── evidence/
│   ├── runtime/
│   └── llm/
└── tests/
    ├── compiler/
    ├── policy/
    ├── runtime/
    └── adapters/
```

## Architecture

```text
LinkML Contract
      ↓
YAML / JSON Recipe
      ↓
Semantic Compiler
      ↓
Cusimanse IR
      ↓
Research State + Event History
      ↓
Deterministic Planner ───────┐
                             ├──→ Capability Resolution
Vercel AI SDK 7 Reasoner ────┘
                                      ↓
                              Policy + Approval
                                      ↓
                              Operation Engine
                                      ↓
                              Adapter Registry
                                      ↓
                    Tool / API / Shell / VM / File / Network
                                      ↓
                         Observation + Evidence
                                      ↓
                              State / Provenance
                                      ↓
                              Next reasoning cycle
```

### Authority boundary

- **LLM:** reason, analyze, and propose declarative intents.
- **CAR:** validate contracts, compile IR, plan deterministically, resolve capabilities, enforce policy, manage approval, execute operations, preserve evidence, and control lifecycle.
- **Adapters:** perform only operations authorized by CAR against registered capabilities.

The LLM never grants itself privileges, changes policy, accesses host credentials, bypasses approval, or turns YAML directly into arbitrary shell commands.

## Build sequence

1. Contract and LinkML validation — **complete**
2. Semantic compiler and normalized IR — **complete**
3. Research state and event model — **complete**
4. Planner and deterministic dependency graph — **current**
5. Capability registry and resolver
6. Policy and approval state machine
7. Validated operation engine
8. Adapter contracts
9. Lima lifecycle and disposable compute
10. Shell, file, process and npm workload adapters
11. Evidence and provenance
12. Vercel AI SDK 7 reasoning layer
13. Observe → reason → propose → validate → authorize → execute loop
14. End-to-end disposable-VM research workflow

## Safety invariant

No adapter receives an executable operation unless the operation has passed contract validation, capability resolution, and the CAR policy/approval gate.
