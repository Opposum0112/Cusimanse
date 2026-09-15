# Deterministic Planner

The CAR planner converts normalized IR intents into a validated dependency graph and deterministic execution order.

## Guarantees

- Intent IDs are unique.
- Every dependency references an existing intent.
- Self-dependencies are rejected.
- Cycles are rejected before execution.
- Independent ready nodes are ordered lexicographically for repeatability.
- Execution order is derived from the declarative IR, never from an LLM proposal.
- `getReadyIntents()` exposes only intents whose dependencies are complete.

The planner is intentionally side-effect free. It does not resolve capabilities, authorize operations, execute adapters, or mutate research state.
