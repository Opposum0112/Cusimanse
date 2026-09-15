# Cusimanse Agent Runtime (CAR)

CAR is an LLM-augmented, domain-specific runtime for security-research contracts. It reads LinkML-governed YAML or JSON, builds a normalized IR, resolves registered capabilities, optionally asks an LLM to propose the next intents, then runs a policy gate before any adapter touches a tool, API, shell, or VM using Vercel AI SDK 7.

**The model proposes. CAR validates and authorizes. Adapters execute.**

## Build status

1. Contract and semantic compiler — complete
2. Research state and event model — complete
3. Deterministic planner and dependency graph — complete
4. Capability registry and resolver — complete
5. Policy and approval state machine — complete
6. Validated operation engine — complete
7. Adapter contracts — complete
8. Lima lifecycle — complete
9. Shell/file/process/npm workload contracts — complete
10. Evidence and provenance — complete
11. Vercel AI SDK 7 proposal reasoning — complete
12. Observe → reason → propose → validate → authorize → execute orchestration — complete
13. Disposable research workflow with guaranteed cleanup — complete

## Architecture

```text
LinkML Contract
      ↓
Compiler → Cusimanse IR → Deterministic Planner
                              ↓
                       Capability Registry
                              ↓
                       Policy + Approval
                              ↓
                       Operation Engine
                              ↓
                         Adapter Registry
                              ↓
                 Lima / Shell / File / Process / npm
                              ↓
                     Observation + Evidence
                              ↓
                         Runtime State
                              ↓
                 Vercel AI SDK 7 Reasoner
                              ↓
                    Declarative Proposal
                              ↺
```

### Authority boundary

- **LLM:** reason, analyze, and propose declarative intent only.
- **CAR:** validate contracts, compile IR, plan deterministically, resolve capabilities, enforce policy, manage approval, execute operations, preserve evidence, and control lifecycle.
- **Adapters:** perform only operations that CAR has authorized.

The reasoning layer exposes no execution tools. Model output must re-enter CAR's validation and authorization path before it can cause an operation. The LLM never grants itself privileges, changes policy, accesses host credentials, bypasses approval, or turns YAML directly into arbitrary shell commands.

## Disposable research lifecycle

```text
Create Lima compute
      ↓
Run CAR orchestration
      ↓
Observe + hash evidence
      ↓
Optional reasoning proposal
      ↓
Destroy compute (finally)
      ↓
Return research state + provenance
```

## Evidence

Evidence records contain SHA-256 content identity, size, URI, evidence kind, and experiment/operation provenance. See `docs/evidence.md`.

## Safety invariant

No adapter receives an executable operation unless the operation has passed contract validation, capability resolution, and the CAR policy/approval gate.
