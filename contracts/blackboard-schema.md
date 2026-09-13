# Blackboard Schema

The blackboard is the shared state contract between specialist agents and the research report/evidence pipeline.

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

## Rules

- Prefer append-only event files.
- Never overwrite raw evidence.
- Findings must reference evidence.
- Verification changes status, not history.
- Agent handoffs should be artifact-based.
- Raw evidence and provenance are retained before compute destruction.

## Core artifacts

`state.json` contains current workflow state. `plan.json` contains objective, hypothesis, success criteria, compute profile and evidence plan. `tasks.jsonl` records one task per line. `findings.jsonl` records claims and evidence references. `decisions.jsonl` records important routing, policy and architecture decisions. `evidence-index.json` maps evidence artifacts to source, collection method, timestamps and hashes.
