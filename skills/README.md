# CAR Skill Registry

The CAR skill registry is a framework-neutral reference catalog for agent skills that may be exposed through CrewAI or another orchestration layer.

A skill describes **research intent**, not executable shell. CrewAI agents should use these definitions to formulate typed CAR proposals. CAR remains responsible for validation, capability resolution, policy, approval, operation lifecycle, adapters, evidence, and disposable compute.

## Skill contract

Each skill definition should declare:

- `id` — stable skill identifier;
- `version` — skill contract version;
- `description` — research purpose;
- `capability` — CAR capability to request;
- `operation_kinds` — allowed CAR operation kinds;
- `parameters` — declarative parameter schema/reference;
- `requires_approval` — whether the skill normally requires policy approval;
- `evidence` — expected evidence categories;
- `agent_roles` — CrewAI roles that may use the skill.

## Registry rules

1. Skills are references, not executable tools.
2. A CrewAI agent must not translate a skill directly into host shell execution.
3. The `capability` must exist in CAR's capability registry before execution.
4. CAR policy is authoritative even when a skill says `requires_approval: false`.
5. Skills should be versioned independently from CrewAI agent prompts.
6. New skills should specify expected observations/evidence so research remains reproducible.

See `skills/registry.yaml` for the initial catalog and `skills/crewai/` for CrewAI-facing role guidance.