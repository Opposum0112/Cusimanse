# Recipe authoring

Recipes are declarative research contracts compiled into CAR IR. Keep commands, capabilities, evidence requirements, scope, and stop conditions explicit.

```yaml
api_version: v1
kind: ExperimentRecipe
experiment_id: npm-install-example
contract_version: v1
runtime: local
scope:
  compute:
    provider: mock
    profile: default
    disposable: true
intents:
  - id: install
    capability: workload.npm.install
    parameters:
      command: npm
      args: [install]
    depends_on: []
operation_kinds: [tool, evidence]
evidence_required:
  - type: process
stop_when:
  all_evidence_required: true
  max_lifetime_minutes: 10
```

Compile before execution:

```bash
cusimanse compile recipes/examples/npm-install.yaml -o /tmp/recipe.ir.json
```

The LinkML-governed schema is `schema/cusimanse-agent-runtime.yaml`. The compiler remains the authoritative runtime validation gate; provider/runtime selection is an execution concern, not a license to bypass contract constraints.
