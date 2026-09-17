# Cusimanse — Native Go Security Research Agent

> **Branch: `adk-cusimanse` — active ADK Go 2 evolution**

Cusimanse is evolving into a **single, native Go security research agent** built on Google ADK Go 2 and governed by a framework-neutral Go capability runtime.

The design is deliberately split into two responsibilities:

- **ADK Go 2** — agent reasoning, planning, workflow orchestration, tool calling, HITL, session state, memory and artifacts.
- **Cusimanse Go runtime** — contracts, requirement resolution, capabilities, policy, authorization, execution boundaries, evidence and audit.

> **The agent decides what to research. Cusimanse decides what may execute.**

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

## Current status

This branch is an architectural migration and integration track. It is not yet a production release.

Implemented in the first increment:

- Go 1.25 baseline.
- Official `google.golang.org/adk/v2` dependency.
- Native Go ADK research-agent package.
- Go capability registry bridged into an ADK function tool.
- Fail-closed policy evaluation before capability execution.
- ADK session state and memory services.
- HITL confirmation on capability requests.
- Atomic durable Cusimanse execution-state journal.
- Native terminal `cusimanse-agent` entry point.
- ADK architecture and migration documentation.

ADK Go 2 is the appropriate foundation for this evolution because it provides graph-based workflows, dynamic workflows and collaborative agent workflows; Go 2.0 became generally available on June 30, 2026. citeturn9search11

## Quick start

### Requirements

- Go 1.25+
- A Google Gemini API key for the current first provider
- macOS or Linux recommended for the disposable-compute integrations

ADK's Go quickstart also requires Go 1.25+ and ADK Go 2.0+. citeturn0search2

### Install

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout adk-cusimanse

go mod download
go test ./...
```

### Configure the model

```bash
export GOOGLE_API_KEY="your-key"
export CUSIMANSE_MODEL="gemini-2.5-flash"
```

The model is currently created through ADK's official Gemini adapter. Provider-neutral model selection is an explicit next migration step rather than being mixed into the security capability layer.

### Start the native agent

```bash
go run ./cmd/cusimanse-agent
```

Optional:

```bash
go run ./cmd/cusimanse-agent \
  --model gemini-2.5-flash \
  --session npm-threat-research-001 \
  --state-dir .cusimanse/state
```

The terminal agent uses an ADK runner and session while the durable Cusimanse journal records the last known execution envelope.

## Architecture

```text
                         Researcher
                             |
                             v
                  +-----------------------+
                  |  Cusimanse ADK Agent  |
                  |       ADK Go 2        |
                  |-----------------------|
                  | Reasoning / Planning  |
                  | Workflow              |
                  | Research Loop         |
                  | Tool Calling          |
                  | HITL                  |
                  | Session State         |
                  | Memory / Artifacts    |
                  +-----------+-----------+
                              |
                       capability request
                              |
                              v
                  +-----------------------+
                  | Cusimanse Go Authority|
                  |-----------------------|
                  | Contract              |
                  | Requirements          |
                  | Capability Registry   |
                  | Policy / Authorization|
                  | Execution Constraints |
                  | Evidence / Audit      |
                  +-----------+-----------+
                              |
                              v
                  +-----------------------+
                  | Disposable Execution  |
                  | Lima / QEMU / Docker  |
                  +-----------+-----------+
                              |
                              v
                    Evidence / Verification
```

ADK's workflow runtime treats agents, tools and functions as workflow nodes, with graph scheduling and resumable workflow state. citeturn11search0turn9search11

## Research loop

The target security-research loop is:

```text
understand
   ↓
load contract + requirements
   ↓
plan
   ↓
resolve capability
   ↓
policy / authorization
   ↓
HITL when required
   ↓
execute in disposable compute
   ↓
observe / collect
   ↓
analyze
   ↓
independent verification
   ↓
acceptance criteria met?
   ├── no → refine plan → bounded retry
   └── yes → report → preserve → destroy
```

The next increment will express this as an explicit ADK Go 2 workflow graph rather than introducing another orchestration framework.

## State, memory and artifacts

ADK separates session state from long-term memory. Session state is the working state for a research session; a persistent `SessionService` determines whether that state survives process restarts. ADK also exposes artifact services for versioned research artifacts. citeturn2search0turn2search1

This branch uses:

| Mechanism | Purpose | Current status |
|---|---|---|
| ADK session state | Research/workflow working state | Enabled |
| ADK memory service | Searchable long-term context | Enabled in development |
| ADK artifacts | Versioned agent artifacts | Integration planned |
| Cusimanse state journal | Atomic crash-safe execution envelope | Enabled |
| Persistent ADK session service | Full process-restart workflow resume | Next increment |
| Persistent memory backend | Durable cross-session research memory | Next increment |
| Evidence ledger | Authoritative observations/provenance | Existing Cusimanse authority |

The ADK Go runner accepts session, artifact and memory services, and the development `InMemoryService` implementations are intended for local development rather than production durability. citeturn7search1turn7search2

## Security boundary

The LLM must never execute shell commands directly.

All execution follows:

```text
LLM intent
   ↓
ADK tool call
   ↓
Go capability registry
   ↓
Cusimanse policy
   ↓
authorization / HITL
   ↓
capability.Check()
   ↓
capability.Execute()
```

Unknown capabilities fail closed. Policy decisions are independent of model output. The existing Go capability interface already separates `Check` and `Execute`, which is retained as the stable authority seam. fileciteturn62file0L2-L2

## Capabilities

The long-term capability surface is:

```text
resolve
provision
configure
instrument
execute
observe
collect
inspect_artifact
analyze_evidence
verify_finding
preserve_evidence
destroy_lab
```

Each capability should have:

- typed input/output;
- explicit authorization requirements;
- policy action mapping;
- bounded execution;
- audit information;
- deterministic or explicitly idempotent behavior;
- evidence/provenance hooks where applicable.

## HITL

ADK Go 2 supports Human-in-the-Loop tool confirmation. The current capability bridge enables confirmation for capability requests. citeturn0search2

HITL is a safety mechanism, not the authority itself. Cusimanse policy remains authoritative even when ADK requests confirmation.

## Model providers

The first implementation uses Gemini through ADK's official Go model integration. ADK Go is designed as a code-first Go agent toolkit and supports multiple model integrations; the Cusimanse architecture intentionally keeps provider selection outside the capability and policy packages. citeturn0search0turn0search2

Planned provider boundary:

```text
ADK model.LLM
      |
      +-- Gemini
      +-- OpenAI-compatible / gateway
      +-- Anthropic-compatible
      +-- Local / Ollama-compatible
      +-- future ADK-compatible providers
```

LiteLLM/OmniRoute may be used as transport/routing infrastructure, but neither is a security boundary.

## Skills and memory

Skills describe how to investigate. Capabilities perform authorized operations. Memory helps the agent recall prior research context. Evidence remains the source of truth for findings.

```text
Skill → reasoning guidance
Memory → reusable context
Capability → authorized action
Evidence → authoritative observation
```

Learning remains approval-gated and cannot mutate policy, trusted profiles or execution authority.

## Disposable execution

Normal execution remains inside disposable compute. Lima/QEMU and other providers are capability implementations, not agent responsibilities.

The agent requests:

```text
provision → instrument → execute → collect → destroy
```

The Go authority validates each stage and records the research lifecycle.

## Evidence lifecycle

```text
collect
  ↓
hash
  ↓
record provenance
  ↓
analyze
  ↓
independent verification
  ↓
preserve
  ↓
destroy disposable compute
```

Model-generated reasoning is never treated as raw evidence.

## Development commands

```bash
go test ./...
go vet ./...
go run ./cmd/cusimanse-agent
```

Repository validation remains available through the existing Cusimanse commands where their dependencies are installed:

```bash
cusimanse validate
cusimanse preflight
cusimanse policy validate
cusimanse test
cusimanse integration-test
```

## Documentation

- [`docs/ADK-GO-2-ARCHITECTURE.md`](docs/ADK-GO-2-ARCHITECTURE.md) — target architecture and authority boundary.
- [`docs/ADK-GO-2-MIGRATION.md`](docs/ADK-GO-2-MIGRATION.md) — staged migration and production gates.
- [`docs/INSTRUMENTATION.md`](docs/INSTRUMENTATION.md) — disposable guest instrumentation.
- [`docs/HOST-TOOLCHAIN.md`](docs/HOST-TOOLCHAIN.md) — host prerequisites and tooling.

## Design principles

1. **Pure Go agent runtime.** No Python agent dependency in this branch.
2. **ADK for orchestration.** Do not recreate an agent framework inside Cusimanse.
3. **Cusimanse for authority.** ADK cannot bypass policy or capabilities.
4. **Evidence over reasoning.** LLM output is not evidence.
5. **Durability by design.** State, approvals and recovery must be replayable.
6. **Disposable execution.** Untrusted workloads stay away from the host.
7. **Provider neutrality.** Model providers must not leak into security policy.
8. **Fail closed.** Unknown capability, policy or profile decisions are denied.
9. **Framework-neutral core.** Capability contracts remain usable by future adapters.
10. **Single-agent product.** The end state is one Go security research agent, not a collection of competing orchestrators.

## Scope of this branch

Only `Opposum0112/Cusimanse` branch `adk-cusimanse` is being changed for this migration. Other repositories and branches are intentionally outside the scope of this work.
