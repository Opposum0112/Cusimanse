# Cusimanse

**Composable Autonomous Threat Research Agent Platform**

Cusimanse is a dedicated security-research agent that plans investigations, calls governed research tools, operates disposable labs, observes behavior, analyzes evidence, verifies findings, and produces reproducible research results.

> **The agent decides what to investigate next. Cusimanse policy decides what it is allowed to execute.**

Cusimanse is provider-neutral across **models, agent tools, execution runtimes, and compute backends**. Vercel AI SDK 7 provides the model and tool-calling substrate; Cusimanse provides the security-research methodology, governance, isolation, evidence, and research state.

## Vercel-native agent direction

The `cusimanse-agent` branch establishes an incremental path toward a Vercel-native runtime:

- **AI SDK 7** — agent/tool substrate and provider-neutral model interface.
- **WorkflowAgent** — target durable, resumable agent execution and approval suspension.
- **AI Gateway** — centralized model routing with ordered provider/model fallbacks.
- **Vercel Sandbox** — hosted disposable Firecracker-backed compute through the Cusimanse ComputeProvider SPI.
- **AI SDK OpenTelemetry** — model/tool telemetry without recording sensitive prompt or output payloads by default.
- **MCP** — interoperable research capability surface alongside native AI SDK tools.
- **Cusimanse state/policy/evidence** — remains authoritative and is not delegated to the model or execution substrate.

The migration is deliberately additive: Temporal, local, Lima, Multipass, and other adapters remain available until equivalent durability, approval, evidence, and regression coverage is demonstrated.

See [`docs/vercel-native-agent-architecture.md`](docs/vercel-native-agent-architecture.md) for the ownership model and migration stages.

## What can it investigate?

Cusimanse is designed for repeatable, evidence-driven security research:

- **Software supply-chain research** — observe package installation and build behavior.
- **Malware analysis** — investigate suspicious workloads inside disposable compute.
- **Vulnerability validation** — reproduce declared behavior within a bounded research scope.
- **Detection engineering** — collect process, filesystem, network, and kernel evidence.
- **Threat research** — test hypotheses and iteratively investigate observations.
- **Agentic security experiments** — let the researcher agent autonomously select the next governed research action.

## The autonomous research loop

A Cusimanse investigation is not just one model response. It is a controlled research loop:

```text
Research objective
       │
       ▼
     PLAN
       │
       ▼
Select capability / tool
       │
       ▼
Policy + approval ───────► DENY
       │
       ▼
    EXECUTE
       │
       ▼
    OBSERVE
       │
       ▼
Analyze evidence
       │
       ▼
Update research state
       │
       ├──── More evidence needed ────► PLAN
       │
       ▼
     VERIFY
       │
       ▼
  Seal evidence
       │
       ▼
 Research result
```
