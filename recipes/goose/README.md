# Goose Project Recipes

This directory defines the Goose execution layer. The project remains recipe-driven: customize YAML recipes rather than rewriting the orchestration engine.

## Flow

1. Goose reads the Markdown contracts and every YAML recipe.
2. Planner builds a stage/workload plan.
3. Reviewer checks host prerequisites, VM profile, instrumentation, monitoring, routing and evidence requirements.
4. Executor runs only approved `labctl`/shell actions and workload commands in disposable VMs.
5. Forensic reviewer analyzes preserved evidence.
6. Independent reviewer checks observations and conclusions.
7. Report generator writes the experiment/SecOps report and token dashboard.

## Customization

- Change `recipes/workloads/*.yaml` for a new workload.
- Change `recipes/lima/profiles/*.yaml` for VM resources/network/mount policy.
- Change `recipes/instrumentation/*.yaml` for collectors.
- Change `recipes/agent-monitoring/*.yaml` for Numbat/Phoenix/OTel settings.
- Change `recipes/gateway/*.yaml` for LLM gateway and harness routing.
- Change `orchestration.yaml` to add/reorder agents or stages.
- Change `token-dashboard.yaml` for token/cost aggregation and optimization.

The evidence store is the durable source for analysis; LLM context should contain deterministic reductions rather than unbounded raw telemetry.

## Agent operation

Goose can be used as the project operator, but the host security boundary remains `labctl`, repository policy and disposable VM isolation. An agent must not receive host credentials or unrestricted mounts. `--apply` is an explicit execution boundary.
