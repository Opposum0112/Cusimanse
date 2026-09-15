# Cusimanse Agent Runtime (CAR)

CAR is an LLM-augmented, domain-specific runtime for security-research contracts. It reads LinkML-governed YAML or JSON, builds a normalized IR, resolves registered capabilities, optionally asks an LLM to propose the next intents, then runs a policy gate before any adapter touches a tool, API, shell, or VM using Vercel AI SDK 7.

**The model proposes. CAR validates and authorizes. Adapters execute.**

## Commit 2 — Contract and semantic compiler

This increment establishes the declarative contract boundary and deterministic compilation path:

```text
LinkML-governed YAML / JSON
          |
          v
   Contract validation
          |
          v
     Semantic compiler
          |
          v
      Cusimanse IR
```

The compiler performs structural and semantic checks at the runtime boundary and normalizes recipe intents into the IR used by later runtime layers. LLM reasoning is deliberately outside this validation boundary.

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
Research State
      ↓
Planner ───────────────┐
                       ├──→ Capability Resolution
Vercel AI SDK 7 ───────┘
                       ↓
                 Policy / Approval
                       ↓
                 Operation Engine
                       ↓
                 Adapter Registry
                       ↓
        Tool / API / Shell / VM
                       ↓
             Observation + Evidence
                       ↓
                State / Provenance
                       ↓
                Next reasoning cycle
```

### Authority boundary

- **LLM:** reason, analyze, and propose declarative intents.
- **CAR:** validate contracts, compile IR, resolve capabilities, enforce policy, manage approval, execute operations, preserve evidence, and control lifecycle.
- **Adapters:** perform only operations authorized by CAR against registered capabilities.

The LLM never grants itself privileges, changes policy, accesses host credentials, bypasses approval, or turns YAML directly into arbitrary shell commands.

## Example

`recipes/examples/npm-install.yaml` demonstrates a LinkML-shaped recipe with a research question, explicit scope, operation kinds, and ordered capability intents.

## Build sequence

1. Contract and LinkML validation — **current**
2. Semantic compiler and normalized IR — **current**
3. Research state and event model
4. Planner and deterministic dependency graph
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
