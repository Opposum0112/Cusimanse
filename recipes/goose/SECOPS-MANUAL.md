# Goose Agentic SecOps Manual

## Purpose

Use Goose to operate the research lifecycle from Markdown requirements and YAML recipes through disposable workload execution, evidence preservation, forensic review and report generation.

## Customization model

Prefer editing recipes over changing automation code:

| Goal | Recipe |
|---|---|
| New workload | `recipes/workloads/*.yaml` |
| VM size/network/mounts | `recipes/lima/profiles/*.yaml` |
| New collector | `recipes/instrumentation/*.yaml` |
| Host agent monitoring | `recipes/agent-monitoring/*.yaml` |
| Agent role | `recipes/goose/agents.yaml` |
| Stage sequence | `recipes/goose/orchestration.yaml` |
| Gateway/model routing | `recipes/gateway/default-gateway.yaml` |
| Harness routing | `recipes/gateway/harness-router.yaml` |
| Token optimisation | `recipes/goose/token-dashboard.yaml` |
| Report format | `recipes/goose/reporting.yaml` |

## Agent execution contract

Goose should first read all applicable Markdown and YAML, resolve references, validate the recipe graph and produce a plan. It should not mutate the host until review and explicit approval are satisfied.

The executor may use shell automation and `labctl`, but workload commands belong in the disposable VM. Host credentials and unrestricted mounts remain prohibited.

## Workload experiment recipe pattern

```yaml
id: example-001
profile: security-research
instrumentation: [process, syscall, network, filesystem]
agent_monitoring: [numbat-agent, phoenix-agent]
workload:
  runtime: npm
  commands:
    - node --version
    - npm --version
    - npm install lodash@4.17.21
evidence:
  preserve_before_destroy: true
  process: true
  syscalls: true
  network: true
  filesystem: true
report:
  recipe: recipes/goose/reporting.yaml
```

Pin workload versions for reproducibility. Keep secrets out of recipe files.

## Agent behaviour monitoring

Monitor the host-side agent process/tool activity independently from VM workload telemetry. Correlate agent actions, gateway calls and workload events using a run identifier. Preserve raw telemetry and use deterministic reductions for LLM analysis.

## Completion criteria

A run is complete only after evidence preservation, forensic review, independent review and report generation. A configured tool is not considered exercised until its runtime behaviour is verified.
