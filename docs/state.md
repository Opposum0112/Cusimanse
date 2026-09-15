# Research State

CAR maintains an append-only event history alongside the current materialized research state. State is runtime-owned; LLM proposals are inputs to the state machine, not authority over it.

## Phase model

```text
created → planning → awaiting-approval → executing → observing
                                      ↘ failed
observing → planning
observing → completed → destroying
```

The event model records lifecycle transitions, operation outcomes, observations, evidence references, and approval decisions. Every event is scoped to its experiment ID.
