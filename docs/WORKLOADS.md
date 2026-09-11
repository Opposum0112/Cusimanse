# Workload-neutral experiment manual

## 1. Install once

Run from a **normal host shell**:

```bash
./scripts/install.sh
./scripts/bin/labctl preflight
./scripts/bin/labctl init --dry-run
./scripts/bin/labctl init --apply
```

The install recipe checks the host before changing it. It does not pipe an unknown remote installer into a shell.

## 2. Run with an AI agent

Antigravity, OpenCode, Goose, Codex or another approved agent may operate the repository. The agent should invoke the same `labctl` CLI from its workspace. There is no privileged agent shell.

Recommended flow:

```text
Agent planner -> YAML plan -> reviewer -> human approval -> labctl --apply -> evidence -> analysis -> verification -> report
```

Agents can inspect and prepare plans without `--apply`. Treat `--apply` as the execution boundary.

## 3. Create a workload

Copy a workload recipe:

```bash
cp recipes/workloads/npm-install-001.yaml recipes/workloads/my-workload.yaml
```

Change:

- `vm_profile`
- `instrumentation_profiles`
- `agent_monitoring_profiles`
- runtime commands
- package/version pins
- evidence requirements

Do not change isolation policy to make an experiment easier to run.

## 4. Add instrumentation

Add a YAML profile under `recipes/instrumentation/`. A profile declares collectors and their tools. The workload selects profiles by ID. This avoids creating a new VM image for every workload.

For a new collector, add:

1. package/tool to the selected Lima profile if required;
2. collector settings to an instrumentation YAML;
3. evidence output and hash rules;
4. a deterministic test recipe;
5. documentation describing kernel/privilege requirements.

## 5. Monitor the agent on the host

Use `recipes/agent-monitoring/numbat-agent.yaml` for host process/tool activity and `phoenix-agent.yaml` for AI traces. Keep both bound to localhost and redact credentials.

The VM workload telemetry and host agent telemetry are separate evidence streams and should be correlated by experiment/run ID.

## 6. Add another runtime

The model is workload-neutral. Add recipes for `pip`, `cargo`, `go`, `npm`, `git`, package managers, compilers, build systems, or other authorized workloads. Prefer pinned versions and benign test inputs.

## 7. Test without execution

```bash
./scripts/tests/validate-recipes.sh
./scripts/bin/labctl init --dry-run
```

Then run the selected experiment only after reviewing the generated Lima profile, instrumentation and evidence destinations.
