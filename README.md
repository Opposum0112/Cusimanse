# Cusimanse Agent Runtime (CAR)

**Cusimanse Agent Runtime (CAR)** is an LLM-augmented, domain-specific runtime that understands LinkML-governed YAML/JSON security-research contracts, reasons over research state, resolves capabilities, and safely translates declarative intent into validated tool, API, VM, and shell operations using Vercel AI SDK 7.

## Purpose

CAR is a fresh runtime foundation. It is not an adapter around another agent harness. External agent frameworks may be integrated later as optional reasoning providers, while CAR remains responsible for contract interpretation, capability resolution, authorization, execution, observation, provenance, and evidence.

## Core pipeline

```text
LinkML contract
      |
YAML / JSON recipe
      |
Parser + semantic validation
      |
Cusimanse IR
      |
Planning + research state
      |
Vercel AI SDK 7 reasoning (optional)
      |
Capability resolution
      |
Policy + approval
      |
Validated Operation
      |
Tool | API | VM | Shell | File | Network
      |
Adapter
      |
Execution + observation
      |
Evidence + provenance
      |
Next reasoning cycle / verification / report
```

### Authority boundary

The LLM can reason, plan, propose intent, analyze observations, and request the next capability. It cannot grant itself privileges, alter policy, bypass approval, directly execute host operations, or redefine the contract. CAR validates and authorizes every concrete operation before an adapter executes it.

### Execution modes

- **Deterministic:** recipe → IR → policy → execution.
- **Assisted:** recipe → IR → LLM proposal → validation → policy → execution.
- **Agentic:** execute → observe → update state → reason → next validated operation.

## Repository structure

```text
schema/       LinkML contracts
recipes/      Declarative YAML/JSON research recipes
src/ir/       Normalized Cusimanse intermediate representation
src/runtime/  Runtime state and execution loop
src/llm/      Vercel AI SDK 7 reasoning integration
src/operations/ Concrete operation contracts
src/capabilities/ Capability registry and resolution
src/policy/   Authorization boundary
src/adapters/ Tool/API/VM/shell adapters
```

This branch is intentionally developed as a standalone CAR refactor. It does not depend on or document another repository branch, agent harness, or previous architecture.
