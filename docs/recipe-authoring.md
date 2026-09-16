# Recipe authoring

CAR recipes are declarative **research contracts**. They describe intent and constraints rather than arbitrary executable shell text.

See [research-contracts.md](research-contracts.md) for the full clause list and deny codes.

## Recipe sections

```yaml
api_version: v1
kind: ExperimentRecipe
experiment_id: unique-experiment-id
contract_version: "0.2"
description: What this experiment investigates.
research_question:
  id: rq-1
  question: What behavior should be observed?
  non_goals:
    - Do not persist the VM.
scope:
  networks: [declared-test-network]
  paths: [/workspace]
  hosts: [disposable-vm]
allowed_capabilities: [vm.create, vm.destroy, evidence.collect]
operation_kinds: [vm, tool, evidence]
intents:
  - id: create-vm
    capability: vm.create
    parameters: {}
    depends_on: []
evidence_required:
  - type: process
    produced_by: evidence.collect
stop_when:
  all_evidence_required: true
  max_proposals: 20
destroy:
  capability: vm.destroy
  require_evidence_sealed: true
```

### Intent

Each intent needs a unique `id` and a registered `capability`. Parameters are passed to capability validation and, after authorization, to the corresponding adapter.

### Dependencies

Use `depends_on` to express prerequisites. CAR builds a dependency graph and produces a deterministic execution order. Missing dependencies, self-dependencies, duplicate IDs, and cycles are rejected.

### Scope

Scope documents the intended research boundary. The contract evaluator currently enforces `working_directory` against `scope.paths`. Concrete adapters and policy rules remain responsible for the rest of the operational boundary.

### Allowlist

If `allowed_capabilities` is set, every static intent and every later agent proposal must name a capability on that list. If it is omitted, CAR does not apply an extra allowlist gate.

## Adding a workload

To add a new workload:

1. Define a stable capability name.
2. Define its operation kind.
3. Add parameter validation.
4. Register the capability.
5. Implement an adapter for the capability.
6. Add policy rules for the operation.
7. Add the name to the experiment allowlist.
8. Add a recipe example.
9. Add tests for validation, authorization, execution, and evidence.

Do not make the recipe itself a shell-command transport. Keep execution behind the adapter boundary.
