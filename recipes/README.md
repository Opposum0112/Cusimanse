# Recipe architecture

The repository uses **small, composable recipes**. `recipes/goose/project.yaml` is the real Goose reference entry recipe; it is intentionally not a monolithic project configuration.

## Recipe composition

```text
Markdown contract
       ↓
experiment composition
       ├── workload
       ├── installation
       ├── host profile
       ├── Lima/VM profile
       ├── tools
       ├── instrumentation
       ├── agent monitoring
       ├── routing
       ├── MCP / skills
       ├── stages / orchestration
       └── reporting / audit
       ↓
Goose reference adapter or another agent adapter
       ↓
approved execution
```

## Recipe families

| Family | Purpose |
|---|---|
| `goose/` | Goose reference project entry workflow |
| `experiments/` | experiment composition |
| `workloads/` | workload definition |
| `install/` | prerequisites and installation |
| `host/` | host profiles |
| `lima/profiles/` | disposable VM profiles |
| `tools/` | tool inventory |
| `instrumentation/` | telemetry profiles |
| `agent-monitoring/` | agent/trace observation |
| `agents/` | provider-neutral agent roles |
| `orchestration/` | execution composition |
| `routing/` | model/harness routing |
| `stages/` | Markdown-to-stage mapping |
| `reporting/` | report generation |
| `token/` | token telemetry configuration; dashboard ownership remains with `policyctl` |
| `mcp/` | MCP registry |
| `skills/` | skills registry |
| `audit/` | append-only audit configuration |
| `tests/` | deterministic recipe validation |

## Schema pattern

Recipe families intentionally do **not** share one forced schema. A recipe should expose fields appropriate to its responsibility. The common conceptual structure is:

```yaml
version: "1"
title: Example capability
description: What this recipe provides
parameters:
  - key: experiment
    input_type: string
    requirement: required
components:
  - name: vm-profile
    path: ../lima/profiles/security-research.yaml
  - name: instrumentation
    path: ../instrumentation/default.yaml
policy:
  approval: required
execution:
  stages:
    - provision
    - instrument
    - execute
    - collect
evidence:
  preserve_before_destroy: required
```

Think of the schema as:

```text
identity → inputs → composition → constraints → execution/evidence requirements
```

Examples:

- a **workload** recipe describes what runs;
- a **VM profile** describes CPU, memory, disk, mounts and networking;
- a **tools** recipe declares required/optional capabilities;
- an **instrumentation** recipe describes telemetry;
- an **experiment** composes those pieces;
- the **Goose entry recipe** defines how Goose consumes the project;
- an adapter for another agent translates the same contracts without changing experiment semantics.

## Customize a recipe

1. Read the applicable Markdown contract and `AGENTS.md`.
2. Identify the smallest capability that needs to change.
3. Select the matching recipe family.
4. Extend an existing recipe only when the capability genuinely differs.
5. Reference the recipe from the experiment composition.
6. Keep credentials out of YAML and Git.
7. Keep host mounts and privileged actions explicit and policy-controlled.
8. Validate with `bash ./scripts/tests/validate-project.sh`.
9. Execute through the selected agent adapter and preserve evidence.

## Execution

Reference Goose execution:

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

A different agent should consume the same experiment and component recipes through its adapter layer. Provider-specific prompts, tool mappings and configuration belong in that adapter, not in shared experiment semantics.
