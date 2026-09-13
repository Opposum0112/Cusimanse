# Recipe architecture

Cusimanse uses **small, composable YAML recipes**. Markdown contracts define required semantics; recipes configure composition; the selected primary agent adapter operates the case.

## Composition

```text
Markdown contract
      ↓
YAML recipe graph
      ├─ campaign / experiment
      ├─ workload / VM / install
      ├─ tools / instrumentation
      ├─ agent / adapter
      ├─ roles / CrewAI orchestration
      ├─ skills / MCP
      └─ audit / reporting
      ↓
selected primary agent
      ↓
approved disposable execution
      ↓
blackboard: runs + audit + evidence + analysis + report
```

## Recipe families

| Family | Purpose |
|---|---|
| `goose/` | Goose reference entry workflow |
| `experiments/` | experiment composition |
| `campaigns/` | research campaign semantics |
| `workloads/` | workload definitions |
| `install/` | installation/prerequisites |
| `host/` | host profiles |
| `lima/profiles/` | disposable VM profiles |
| `tools/` | tool inventory |
| `instrumentation/` | telemetry profiles |
| `agent-monitoring/` | agent/trace observation |
| `agents/` | provider-neutral agent contracts |
| `adapters/` | provider-specific translation |
| `orchestration/` | specialist roles and orchestration |
| `routing/` | model/harness routing |
| `mcp/` | scoped MCP integrations |
| `skills/` | versioned skill registry |
| `audit/` | append-only audit configuration |
| `reporting/` | report generation |
| `tests/` | deterministic recipe validation |

## Pluggable role/skill contract

`recipes/orchestration/role-skill-plugin.yaml` defines the provider-neutral plugin model. A role may declare skills, tools and MCP integrations and must return structured results. The selected primary agent remains the only case operator/executor.

Role and skill plugins are capabilities, not security boundaries. Retrieval never grants execution authority. Plugin changes are declarative and reviewable.

## Security rules

- Keep credentials out of recipes and Git.
- Keep host mounts and privileged actions explicit and policy-controlled.
- Never allow a role, skill, MCP server or orchestrator to bypass the VM/OS boundary.
- Preserve raw evidence before VM destruction.
- Treat external skills as `candidate-review-required` until provenance, permissions, scripts, network behavior and capabilities are reviewed.
- Missing capabilities are `NOT_DEPLOYED`.

## Reference execution

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

Other adapters consume the same experiment semantics through their adapter contract. Provider-specific prompts, CLI mappings and tool integration belong in the adapter layer rather than shared campaign semantics.
