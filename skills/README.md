# CAR Skill Registry

The skill registry is a framework-neutral vocabulary for security-research capabilities consumed by agent integrations such as CrewAI.

A skill describes **what research capability an agent may request**. It does not grant execution authority.

```text
Agent / Crew
    ↓
Skill Registry
    ↓
Declarative intent
    ↓
CAR capability resolution
    ↓
Policy + approval
    ↓
Operation + adapter
```

## Rules

- Skills reference CAR capabilities; they do not contain shell commands.
- Skills do not contain credentials or policy overrides.
- CrewAI agents should select skills rather than directly invoking host tools.
- CAR remains authoritative for validation, authorization and execution.
- New agent frameworks can reuse the same registry vocabulary.

See `registry.yaml` for the initial skill catalog and `crewai/README.md` for CrewAI consumption guidance.
