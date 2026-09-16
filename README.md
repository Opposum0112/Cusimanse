# Cusimanse

**Explore. Experiment. Verify. Learn.**

Cusimanse is a **harness-neutral security research runtime** for supply-chain security, malware analysis, vulnerability validation, and isolated agentic experiments.

The key idea is simple:

> **Your AI agent or coding harness is the operator. Cusimanse is the controlled research runtime underneath it.**

You can use a harness such as **DeepSeek-based agents, OpenAI Codex, Grok Build, or your own agent** to decide what to investigate. Cusimanse turns that intent into a governed research operation: validate the contract, resolve capabilities, apply policy and approvals, run inside the selected compute environment, collect evidence, and return state/results to the operator.

Cusimanse does **not** require a particular LLM, agent framework, IDE, or orchestration product.

> **Safety boundary:** AI agents propose research actions; contracts, policy, approvals, and sandbox boundaries decide what can execute. Never treat a model, recipe, provider, VM, or probe as a security guarantee.

## Why use Cusimanse?

If you already have an AI coding agent or research harness, you do **not** need to replace it.

Use your existing agent for:

- understanding the research question;
- reasoning about hypotheses;
- deciding what information it needs;
- proposing the next research operation;
- interpreting evidence;
- writing the final analysis.

Use Cusimanse for the controlled execution boundary:

- declarative research contracts and recipes;
- LinkML-governed research data;
- capability resolution;
- policy and approval checks;
- execution lifecycle and state;
- disposable compute providers;
- guest instrumentation through `labprobe`;
- evidence collection and sealing;
- runtime/provider abstraction.

This separation lets you change the AI operator without rewriting the research environment.

## The operator model

Think of Cusimanse as the **research operating layer**, not as another chat agent.

```text
┌─────────────────────────────────────────────────────────────────┐
│                    YOUR AI OPERATOR / HARNESS                   │
│                                                                 │
│  DeepSeek agent   Codex   Grok Build   Claude   custom agent    │
│                                                                 │
│  Understand → reason → propose → inspect evidence → repeat     │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                     OperatorPort / HTTP / CLI
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                         CUSIMANSE                               │
│                                                                 │
│  Contract → IR → capabilities → policy/approval → runtime      │
│                                      │                          │
│                             compute provider                   │
│                                      │                          │
│                         disposable environment                 │
│                                      │                          │
│                              labprobe                           │
│                                      │                          │
│                         evidence + state                        │
└─────────────────────────────────────────────────────────────────┘
```

The **operator chooses what to investigate**. Cusimanse controls **what is allowed to execute and how the experiment is recorded**.

### What is a harness?

A harness is the environment that runs your AI agent and gives it capabilities such as model access, tools, files, shell commands, HTTP requests, MCP, or workflow orchestration.

Cusimanse intentionally does not depend on one harness. A harness only needs a way to call one of the supported operator interfaces.

### What is the integration boundary?

The stable conceptual boundary is `OperatorPort`:

```ts
interface OperatorPort {
  submitProposal(request): Promise<OperatorIntentResponse>;
  getState(experimentId): Promise<OperatorStateResponse>;
  getEvidence(experimentId): Promise<OperatorEvidenceResponse>;
}
```

This means an agent can follow the same loop regardless of which model or harness is underneath:

```text
1. Read research state
2. Reason about the next step
3. Submit a proposal
4. Cusimanse validates and executes it
5. Read resulting state/evidence
6. Continue or finish
```

The agent is therefore an **operator**, not the security boundary.

## Bring your own AI agent or harness

There are three practical integration styles.

### 1. CLI integration — simplest

Use any harness that can execute shell commands.

```bash
# Validate/compile a research recipe
cusimanse compile recipes/examples/npm-install.yaml

# Run through the local runtime and mock compute provider
cusimanse run recipes/examples/npm-install.yaml \
  --runtime local \
  --provider mock
```

Your harness can treat Cusimanse as a deterministic research tool:

```text
AI harness
   │
   ├── writes/chooses recipe.yaml
   ├── calls `cusimanse compile ...`
   ├── calls `cusimanse run ...`
   └── reads output/evidence
```

This works well for coding agents and CLI-oriented research workflows.

### 2. HTTP integration — best for long-running agents

Start the operator gateway:

```bash
cusimanse serve --port 8787
```

The gateway exposes the harness-neutral operator surface:

```text
GET  /v1/research/<experimentId>/state
GET  /v1/research/<experimentId>/evidence
POST /v1/research/<experimentId>/proposals
```

A harness that can make HTTP requests can therefore operate Cusimanse without knowing its TypeScript internals.

Conceptually:

```text
AI agent
   │
   ├── GET  /state
   │
   ├── reason
   │
   ├── POST /proposals
   │
   ├── GET  /state
   │
   └── GET  /evidence
   │
   ▼
Cusimanse gateway → policy → runtime → compute → evidence
```

The proposal endpoint is intentionally not a general-purpose arbitrary shell endpoint. The proposal must conform to the research proposal contract and execution still goes through the Cusimanse runtime.

### 3. TypeScript/library integration — native embedding

If your harness is itself a Node.js/TypeScript application, import Cusimanse directly:

```ts
import {
  CARGateway,
  RuntimeOrchestrator,
  createToolLoopAgent,
} from "@cusimanse/agent-runtime";
```

This allows a custom harness to embed the runtime while retaining the same contract, policy, runtime, compute, and evidence boundaries.

## Using DeepSeek, Codex, Grok Build, or another harness

Cusimanse is **model/harness neutral**. The integration does not depend on the brand of the model.

### DeepSeek-based harness

Use the DeepSeek agent as the reasoning/operator layer. Give it access to the Cusimanse CLI or gateway and instruct it to:

```text
1. Read the research contract.
2. Inspect current Cusimanse state.
3. Propose only the next declared research capability.
4. Submit the proposal through the Cusimanse operator interface.
5. Inspect returned evidence.
6. Repeat until the research question is answered.
```

The DeepSeek model decides what it wants to investigate; Cusimanse remains responsible for validating and executing the resulting operation.

### OpenAI Codex

Codex can operate Cusimanse as a repository/CLI tool:

```text
Codex
  ↓
Cusimanse CLI
  ↓
recipe → IR → policy → runtime → sandbox
  ↓
evidence/state
  ↓
Codex analysis
```

For a richer integration, a Codex-compatible environment can expose the Cusimanse gateway or an adapter implementing `OperatorPort`.

### Grok Build

A Grok Build-based agent can use the same boundary if its environment can invoke shell commands or HTTP APIs:

```text
Grok Build
    ↓
Operator interface
    ↓
Cusimanse
    ↓
isolated research execution
    ↓
evidence
    ↓
Grok analysis
```

There is deliberately **no vendor-specific execution path required**. DeepSeek, Codex, Grok Build, or another agent can all become operators over the same research runtime.

> These are integration patterns, not claims that Cusimanse currently ships first-party native adapters for each named product. A native adapter can be added without changing the research contract or compute/runtime SPIs.

## End-user quick start

Requires Node.js **22+**. Go 1.22+ is required for `labprobe` development.

```bash
npm install
npm run typecheck
npm test
npm run build
```

### Run the example

Compile the reference recipe:

```bash
cusimanse compile recipes/examples/npm-install.yaml
```

Run it using the deterministic mock provider:

```bash
cusimanse run recipes/examples/npm-install.yaml \
  --runtime local \
  --provider mock
```

Start the gateway when you want an external agent/harness to operate the runtime:

```bash
cusimanse serve --port 8787
```

The existing reference lab remains available with:

```bash
npm run lab:npm-install
```

It uses placeholder adapters and does not claim to boot a real VM.

## From research question to evidence

A normal user workflow looks like this:

```text
Research question
      ↓
Research contract / YAML recipe
      ↓
Compile + validate
      ↓
Intermediate Representation (IR)
      ↓
Resolve required capabilities
      ↓
Policy + human approval where required
      ↓
Select execution runtime
      ↓
Select compute provider
      ↓
Create disposable research environment
      ↓
Run workload
      ↓
labprobe collects telemetry
      ↓
Evidence + artifacts
      ↓
Agent analyzes results
      ↓
Independent verification / report
```

The important distinction is:

- **Recipe/contract:** what the research intends to do.
- **Agent/harness:** why/when the next step should be proposed.
- **Cusimanse runtime:** whether/how that proposal can execute.
- **Compute provider:** where it executes.
- **labprobe:** what happens inside the guest and what evidence is collected.

## Unified CLI

| Command | Purpose |
|---|---|
| `cusimanse compile <recipe.yaml>` | Validate declarative input and produce IR |
| `cusimanse run <recipe.yaml> --runtime <local\|temporal\|graph> --provider <mock\|lima\|multipass\|cloud>` | Execute through the selected runtime/provider boundary |
| `cusimanse serve --port 8787` | Start the operator HTTP gateway |
| `cusimanse skills promote <candidate-dir>` | Validate and promote a candidate skill |

Runtime choices are deliberately pluggable:

- **local** — in-process execution for development and deterministic tests.
- **temporal** — `TemporalWorkflowDriver` seam for durable workflow infrastructure.
- **graph** — `GraphWorkflowDriver` seam for cyclic/adversarial graph engines such as LangGraph.

## Compute providers

The `ComputeProvider` SPI is the stable boundary for **where** a workload executes. Its contract covers sandbox creation, command execution, artifact movement, and destruction.

Available/adaptable providers include:

- **Mock** — deterministic test provider.
- **Lima** — command-backed local VM provider.
- **Multipass** — command-backed local VM provider.
- **Firecracker / Cloud** — `DelegatingComputeProvider` seam for an external driver or service.

Provider selection is separate from agent selection. Changing from Codex to DeepSeek, for example, does not require changing the recipe or compute provider.

Provider availability never bypasses policy. A registered provider is not automatically authorized for every experiment.

## AI agent layer

Cusimanse exposes AI SDK 7 agent primitives through `createToolLoopAgent()` and `createWorkflowAgent()`. These are **agent-runtime primitives**, not the security boundary.

The default reasoning posture is proposal-oriented:

```text
Agent reasoning
      ↓
proposal
      ↓
Cusimanse contract/policy checks
      ↓
execution runtime
```

Workflow durability and compute execution remain behind Cusimanse's runtime/provider boundaries so the surrounding harness can change without changing the research definition.

## MCP

MCP can be used as a separate interface for research state and evidence access. It does **not** grant execution authority by itself.

This enables a useful pattern for agentic research:

```text
Agent
 ├── MCP → inspect research state/evidence
 └── Operator interface → submit governed proposal
```

Keep observation and execution authority separate.

## Data plane: `labprobe`

`probe/cmd/labprobe` is the Go guest daemon boundary. It provides a small capability model for:

- preflight verification;
- process telemetry;
- network telemetry;
- syscall telemetry;
- future platform-specific eBPF collectors.

The `EBPFCollector` interface is intentionally separate from the control plane so kernel instrumentation can evolve without changing the TypeScript orchestration contract.

Build/run the probe from the repository root:

```bash
go build ./probe/cmd/labprobe
go test ./probe/...
```

## Skills: candidate → validated

New research capabilities follow a promotion lifecycle:

```text
skills/candidate/<skill>/
        │ structural validation + review
        ▼
skills/validated/<skill>/
        │
        ▼
contract allowlist → policy → approval → execution
```

Promotion is **not** authorization. A validated skill still requires an explicit contract capability and policy decision.

## Example: npm supply-chain research

The reference recipe is `recipes/examples/npm-install.yaml`. It declares the research question, scope, compute preference, capability allowlist, intents, evidence requirements, stop conditions, and destruction rule.

An AI operator can use it like this:

```text
User: Investigate what happens when this package is installed.

Agent:
  1. Read the recipe and research state.
  2. Identify the next allowed capability.
  3. Submit a proposal.

Cusimanse:
  4. Validate capability and policy.
  5. Execute in the selected environment.
  6. Collect evidence.
  7. Return updated state/evidence.

Agent:
  8. Analyze evidence.
  9. Propose the next step or finish the investigation.
```

Keep experiment definitions declarative; provider-specific implementation belongs under `src/adapters/compute/`.

## Repository layout

```text
src/
  agent/                 AI SDK 7 agent primitives
  adapters/compute/     Compute Provider SPI + providers
  capabilities/         Capability registry/resolution
  compiler/             Recipe → IR compiler
  contract/             Research-contract checks
  gateway/              Harness-neutral operator HTTP boundary
  llm/                  Proposal-only reasoner
  mcp/                  MCP state/evidence server
  operations/           Operation lifecycle
  planner/              Dependency planning
  policy/               Policy and approval engine
  runtime/              Execution Runtime SPI + implementations
  state/                 Research state/event model
probe/
  cmd/labprobe/         Go guest probe daemon
  internal/probe/       Probe capability model + eBPF seam
recipes/                 Declarative experiment examples
labs/                    Reference research labs
skills/
  candidate/             Experimental skills
  validated/             Reviewed skills
schema/                  Runtime schema
contracts/               Research contracts (when present)
docs/                    Architecture and researcher guides
.github/                 CI, issue templates, PR template
```

## Extending Cusimanse for a new harness

You do **not** need to modify the research recipe to support another AI harness.

A new integration normally needs only an adapter that maps the harness's tool/API mechanism to the operator boundary:

```text
New Harness
     │
     ▼
Harness Adapter
     │
     ▼
OperatorPort
     │
     ├── getState()
     ├── getEvidence()
     └── submitProposal()
     │
     ▼
Cusimanse Runtime
```

For example, a future adapter could expose Cusimanse as:

- a shell tool for a CLI agent;
- an HTTP tool for a hosted agent;
- an MCP tool for state/evidence workflows;
- a native SDK integration for a TypeScript harness;
- a workflow node for a graph-based agent system.

The adapter should translate **intent**, not bypass the runtime. Do not turn a harness adapter into an unrestricted shell bridge.

## Production-readiness boundaries

- **Governance:** Apache License 2.0, `SECURITY.md`, `CONTRIBUTING.md`, issue/PR templates.
- **Isolation:** disposable compute is a required design boundary for untrusted workloads; it is not a universal security guarantee.
- **Policy:** models and skills cannot approve themselves.
- **Evidence:** evidence is part of the research lifecycle, not an optional side effect.
- **Pluggability:** runtime and compute implementations can be replaced without rewriting research contracts.
- **Observability:** control-plane state, gateway access, guest telemetry, and research artifacts remain separately attributable.

## Validation

```bash
npm run typecheck
npm test
npm run build
go test ./probe/...
cusimanse compile recipes/examples/npm-install.yaml
```

For an actual Lima integration, use the repository's dedicated sandbox/integration workflow and ensure the host has Lima/QEMU installed. Do not interpret the mock provider as VM isolation.

## Security and contribution

Read [`SECURITY.md`](SECURITY.md) before running untrusted workloads and [`CONTRIBUTING.md`](CONTRIBUTING.md) before submitting changes. See the Apache License 2.0 in [`LICENSE`](LICENSE).
