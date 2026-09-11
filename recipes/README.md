# Recipe architecture

The repository uses **small, composable recipes**. `recipes/goose/project.yaml` is a real Goose entry recipe; it is not a monolithic configuration file.

| Family | Purpose |
|---|---|
| `goose/` | project entry workflow |
| `experiments/` | experiment composition |
| `workloads/` | workload definition |
| `install/` | prerequisites and installation |
| `host/` | host profiles |
| `lima/profiles/` | disposable VM profiles |
| `tools/` | tool inventory |
| `instrumentation/` | telemetry profiles |
| `agent-monitoring/` | agent telemetry |
| `mcp/` | MCP registry and bootstrap |
| `skills/` | skill registry and bootstrap |
| `audit/` | audit layer |
| `agents/` | agent roles |
| `orchestration/` | execution stages |
| `routing/` | model/harness routing |
| `stages/` | Markdown contract mapping |
| `reporting/` | reports |
| `token/` | token usage data; web dashboard is owned by `policyctl` |
| `tests/` | deterministic validation |

## Simple execution

Install/configure Goose first, then from the repository root:

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

For a single numbered section:

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=07
```

The project recipe performs prerequisite resolution before the requested section. Privileged operations still stop for approval.
