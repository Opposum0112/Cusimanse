# 10 — Validation and Acceptance

![Experiment workflow](../docs/images/cusimanse-workflow.png)

## Validation levels

- [ ] Host prerequisites pass.
- [ ] Goose project recipe loads.
- [ ] Installation/preflight resolves required capabilities.
- [ ] MCP registry is resolved.
- [ ] Skill registry is validated.
- [ ] Audit layer records the run.
- [ ] Disposable VM boots and can be destroyed.
- [ ] Instrumentation starts before workload.
- [ ] Evidence is preserved and hashed.
- [ ] Findings are independently verified.
- [ ] Research report is generated.
- [ ] Token telemetry is available to `policyctl token-dashboard`.

## Acceptance states

| State | Meaning |
|---|---|
| `PASS` | required workflow and controls were exercised and evidenced |
| `PARTIAL` | workflow works but optional capability is unavailable |
| `FAIL` | mandatory safety/reproducibility boundary is broken |
| `NOT_DEPLOYED` | capability is not installed or not exercised |

Configuration files alone never establish PASS.
