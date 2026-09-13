# 06 — Observability and Evidence

![Experiment workflow](../docs/images/cusimanse-workflow.png)

## Two telemetry domains

### Agent telemetry

Model/provider, tokens, latency, tool calls, routing, errors and handoffs.

### Workload telemetry

Processes, syscalls, filesystem changes, DNS, sockets, packets and security events.

## Evidence lifecycle

```text
capture → preserve → hash → reduce → analyse → verify → report
```

Raw evidence remains the ground truth. LLM context should receive deterministic reductions whenever practical.

## Formats

- JSON — manifests and structured state
- JSONL/NDJSON — event streams
- PCAP — packet evidence
- text — command/tool output

## Audit vs evidence

The audit layer answers **what the agent workflow requested and did**. Experiment evidence answers **what the workload actually did**. They must not be conflated.
