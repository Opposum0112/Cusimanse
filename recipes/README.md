# YAML recipe architecture

The `recipes/` tree is the declarative project configuration surface. `recipes/goose/project.yaml` is the entry recipe; it composes small reusable recipes instead of becoming one giant configuration file.

## Recipe families

| Directory | Purpose |
|---|---|
| `goose/` | Goose project entry recipe and operating instructions |
| `experiments/` | experiment compositions |
| `workloads/` | workload definitions |
| `install/` | host prerequisites and installation |
| `host/` | host profiles |
| `lima/profiles/` | disposable VM profiles |
| `tools/` | reusable host/VM/tool definitions |
| `instrumentation/` | instrumentation profiles |
| `agent-monitoring/` | Numbat/Phoenix/OTel profiles |
| `agents/` | agent roles |
| `orchestration/` | multi-agent execution chain |
| `routing/` | model gateway and harness routing |
| `stages/` | Markdown contract stage mapping |
| `reporting/` | report recipes |
| `token/` | token/cost recipes |
| `tests/` | recipe validation |

The agent selects and composes these recipes. Do not duplicate a VM or instrumentation profile for a single workload unless the capability genuinely differs.
