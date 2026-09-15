# Cusimanse Agent Runtime (CAR)

CAR is an LLM-augmented, domain-specific runtime for security-research contracts. It reads LinkML-governed YAML or JSON, builds a normalized IR, resolves registered capabilities, optionally asks an LLM to propose the next intents, then runs a policy gate before any adapter touches a tool, API, shell, or VM using Vercel AI SDK 7.

**The model proposes. CAR validates and authorizes. Adapters execute.**

## Build sequence

1. Contract and LinkML validation — complete
2. Semantic compiler and normalized IR — complete
3. Research state and event model — complete
4. Planner and deterministic dependency graph — complete
5. Capability registry and resolver — complete
6. Policy and approval state machine — complete
7. Validated operation engine — complete
8. Adapter contracts — complete
9. Lima lifecycle and disposable compute — complete
10. Shell, file, process and npm workload adapters — complete
11. Evidence and provenance — complete
12. Vercel AI SDK 7 reasoning layer
13. Observe → reason → propose → validate → authorize → execute loop
14. End-to-end disposable-VM research workflow

## Architecture

```text
LinkML Contract → Compiler → IR → Planner
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
                      LLM Reasoning Layer
                              ↓
                     Next Intent Proposal
```

### Authority boundary

- **LLM:** reason, analyze, and propose declarative intents.
- **CAR:** validate contracts, compile IR, plan deterministically, resolve capabilities, enforce policy, manage approval, execute operations, preserve evidence, and control lifecycle.
- **Adapters:** perform only operations authorized by CAR against registered capabilities.

The LLM never grants itself privileges, changes policy, accesses host credentials, bypasses approval, or turns YAML directly into arbitrary shell commands.

## Evidence

Evidence is recorded with SHA-256 content identity, size, URI, and experiment/operation provenance. See `docs/evidence.md`.

## Safety invariant

No adapter receives an executable operation unless the operation has passed contract validation, capability resolution, and the CAR policy/approval gate.
