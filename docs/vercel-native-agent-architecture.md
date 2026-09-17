# Cusimanse Vercel-Native Agent Architecture

This branch establishes the migration path toward a Vercel AI SDK 7 native agent runtime without moving security authority into the model framework.

## Ownership model

| Concern | Cusimanse | Vercel / AI SDK |
| --- | --- | --- |
| Security-research contracts | Authoritative | Consumes |
| Capability resolution | Authoritative | Tool substrate |
| Policy and scope | Authoritative, fail-closed | Approval transport |
| Research state and evidence provenance | Authoritative | Workflow state can persist execution |
| Agent reasoning and tool loop | Domain instructions/tools | AI SDK 7 |
| Durable agent execution | Migration target | `WorkflowAgent` + Workflow SDK |
| Model routing/fallback | Declarative policy | AI Gateway |
| Disposable hosted compute | Compute SPI | Vercel Sandbox adapter |
| Telemetry | Research events | AI SDK OpenTelemetry |
| External capability interoperability | MCP surface | AI SDK MCP client/server integrations |

## Target flow

```text
Research Contract
      |
      v
Cusimanse Agent Core
      |
      +---- Research State / Evidence Journal
      |
      v
Vercel AI SDK 7
      |
      +---- WorkflowAgent
      |       |
      |       +---- durable tool steps
      |       +---- resumable approvals
      |       +---- streaming
      |
      +---- AI Gateway
      |       |
      |       +---- primary model
      |       +---- ordered fallback models/providers
      |
      +---- governed AI SDK / MCP tools
      |
      v
Cusimanse Policy + Approval
      |
      v
Compute SPI
      |
      +---- Vercel Sandbox
      +---- Lima
      +---- Multipass
      +---- Firecracker/Cloud
      |
      v
Telemetry -> Evidence -> Research State -> next plan
```

## Security boundary

AI SDK tool calling is not authorization. Every research operation remains subject to Cusimanse contract scope, capability resolution, policy evaluation, approval, lifecycle rules, and evidence requirements.

The agent must not receive an unrestricted shell primitive. Security operations should be exposed as typed domain tools such as `create_lab`, `execute_workload`, `observe_network`, `query_telemetry`, `inspect_artifact`, `verify_finding`, and `destroy_lab`.

## Migration stages

1. **Foundation** — centralize AI Gateway model configuration and add the Vercel Sandbox compute adapter.
2. **Durability** — replace the primary in-memory `ToolLoopAgent` loop with `WorkflowAgent` inside a Workflow SDK workflow.
3. **Approval** — map high-risk Cusimanse policy decisions to AI SDK `needsApproval` while retaining Cusimanse policy as the authoritative gate.
4. **Streaming** — expose workflow-aware streams containing tool/research lifecycle events, not private chain-of-thought.
5. **Observability** — register AI SDK OpenTelemetry and correlate spans with Cusimanse `runId`, `traceId`, and `experimentId`.
6. **Runtime convergence** — make the Vercel workflow runtime the primary hosted runtime while retaining local compute/runtime adapters for portability and offline research.
7. **Retirement** — remove Temporal only after equivalent durability, approval, retry, replay, evidence, and integration tests pass.

## Current branch status

The branch intentionally keeps Temporal and the existing local runtime available. The new Vercel-native seams are additive so the migration can be incremental and reversible.
