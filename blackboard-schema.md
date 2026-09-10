# Blackboard Schema

The blackboard is the shared state contract between agents.

```text
blackboard/
├── state.json
├── plan.json
├── tasks.jsonl
├── findings.jsonl
├── decisions.jsonl
├── research.json
├── security-review.json
├── routing.json
└── evidence-index.json
```

## state.json

Contains current workflow state.

## plan.json

Contains objective, hypothesis, success criteria, experiment profile and evidence plan.

## tasks.jsonl

One task per line.

Example:

```json
{"task_id":"T001","role":"planner","status":"completed","artifact":"plan.json"}
```

## findings.jsonl

One finding per line.

```json
{"finding_id":"F001","claim":"...","evidence":["..."],"confidence":0.95,"verified":false}
```

## decisions.jsonl

Records important routing, policy and architecture decisions.

## evidence-index.json

Maps evidence artifacts to source, collection method, timestamps and hashes.

## Rules

- Prefer append-only event files.
- Never overwrite raw evidence.
- Findings must reference evidence.
- Verification changes status, not history.
- Agent handoffs should be artifact-based.
