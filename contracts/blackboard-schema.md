# Evidence and handoff model

Cusimanse does not require a blackboard service. Goose subagents/subrecipes have isolated sessions, so durable handoff is done through explicit files in the experiment run directory.

```text
experiments/<experiment>/runs/<run-id>/
├── evidence/
├── analysis.md
├── verification.md
└── report.md
```

## Rules

- Pass evidence paths explicitly to subrecipes.
- Never overwrite raw evidence.
- Findings must reference observable artifacts.
- Verification reviews the evidence independently.
- Preserve the evidence directory before considering the run complete.

This filesystem model replaces the previous custom shared-state service and keeps the project within Goose-native primitives.
