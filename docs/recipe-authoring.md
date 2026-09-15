# Recipe authoring

CAR recipes are declarative research contracts. They describe intent and constraints rather than arbitrary executable shell text.

## Recipe sections

```yaml
api_version: v1
kind: ExperimentRecipe
experiment_id: unique-experiment-id
description: What this experiment investigates.
research_question:
  id: rq-1
  question: What behavior should be observed?
scope:
  networks: [declared-test-network]
  paths: [/workspace]
  hosts: [disposable-vm]
operation_kinds: [vm, tool, evidence]
intents:
  - id: create-vm
    capability: vm.create
    parameters: {}
    depends_on: []
```

### Intent

Each intent needs a unique `id` and a registered `capability`. Parameters are passed to capability validation and, after authorization, to the corresponding adapter.

### Dependencies

Use `depends_on` to express prerequisites. CAR builds a dependency graph and produces a deterministic execution order. Missing dependencies, self-dependencies, duplicate IDs, and cycles are rejected.

### Scope

Scope documents the intended research boundary. Concrete adapters and policy rules remain responsible for enforcing operational boundaries.

## Adding a workload

To add a new workload:

1. Define a stable capability name.
2. Define its operation kind.
3. Add parameter validation.
4. Register the capability.
5. Implement an adapter for the capability.
6. Add policy rules for the operation.
7. Add a recipe example.
8. Add tests for validation, authorization, execution, and evidence.

Do not make the recipe itself a shell-command transport. Keep execution behind the adapter boundary.
