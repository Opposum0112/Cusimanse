# Cusimanse

**Explore. Experiment. Verify. Learn.**

Cusimanse is a harness-neutral, open-source threat-research platform for **supply-chain security, malware analysis, vulnerability validation, and isolated agentic execution**. The design separates a TypeScript control plane from Go data-plane probes and keeps both workflow orchestration and compute infrastructure behind explicit SPIs.

> **Safety boundary:** AI agents propose research actions; contracts, policy, approvals, and sandbox boundaries decide what can execute. Never treat a model, recipe, provider, VM, or probe as a security guarantee.

## Architecture

```text
                         CONTROL PLANE — Node.js 22+ / ESM
┌────────────────────────────────────────────────────────────────────────────┐
│ Harness adapters / researcher / MCP                                        │
│                 ↓                                                          │
│ AI Engine: ToolLoopAgent + WorkflowAgent (Vercel AI SDK 7)                │
│                 ↓                                                          │
│ Contract + LinkML validation → IR → Policy / Approval → Runtime SPI       │
│                                      │             │                        │
│                         local / temporal / graph │                        │
│                                      ↓             ↓                        │
│                              Compute Provider SPI                          │
│                        Lima / Multipass / Firecracker / Cloud              │
└──────────────────────────────────────┬─────────────────────────────────────┘
                                       │ isolated execution
┌──────────────────────────────────────▼─────────────────────────────────────┐
│                         DATA PLANE — Go / labprobe                         │
│       preflight • process • network • syscall • eBPF telemetry             │
│                         evidence → artifacts                               │
└────────────────────────────────────────────────────────────────────────────┘
```

AI SDK 7 provides `ToolLoopAgent` for bounded in-process agent loops and `WorkflowAgent` for durable agent execution; Cusimanse keeps those agent primitives above its own policy and execution boundaries. citeturn0search0turn0search5

## Research loop

```text
Research question
  → contract + LinkML-governed data
  → declarative recipe
  → IR compilation
  → capability resolution
  → policy / human approval
  → execution runtime
  → isolated compute
  → labprobe telemetry
  → evidence sealing
  → analysis / verification / report
```

The **control plane decides and coordinates**. The **data plane observes the guest**. Neither layer should silently become the other.

## Researcher quick start

Requires Node.js **22+**. Go 1.22+ is required for `labprobe` development.

```bash
npm install
npm run typecheck
npm test
npm run build
```

Compile a recipe into the intermediate representation:

```bash
npx cusimanse compile recipes/examples/npm-install.yaml
```

Run the reference experiment with the mock provider:

```bash
npx cusimanse run recipes/examples/npm-install.yaml --runtime local --provider mock
```

Start the operator gateway:

```bash
npx cusimanse serve --port 8787
```

The existing reference lab remains available with `npm run lab:npm-install`; it uses placeholder adapters and does not claim to boot a real VM.

## Unified CLI

| Command | Purpose |
|---|---|
| `cusimanse compile <recipe.yaml>` | Validate declarative input and produce IR |
| `cusimanse run <recipe.yaml> --runtime local --provider mock` | Execute through the selected SPI |
| `cusimanse serve --port 8787` | Start the operator HTTP gateway |
| `cusimanse skills promote <candidate-dir>` | Validate and promote a candidate skill |

Runtime choices are deliberately pluggable:

- **local** — in-process execution for development and deterministic tests.
- **temporal** — `TemporalWorkflowDriver` seam for durable workflow infrastructure.
- **graph** — `GraphWorkflowDriver` seam for cyclic/adversarial graph engines such as LangGraph.

## Compute Provider SPI

`ComputeProvider` is the stable boundary for **where** a workload executes. Its contract covers sandbox creation, command execution, artifact movement and destruction.

Implemented/adaptable providers:

- **Lima** — command-backed local VM provider.
- **Multipass** — command-backed local VM provider.
- **Mock** — deterministic test provider.
- **Firecracker / Cloud** — `DelegatingComputeProvider` seam for an external driver or service.

Provider availability never bypasses policy. A provider can be registered without being authorized for a particular experiment.

## Agent and MCP boundaries

The control plane exposes factories for AI SDK 7 `ToolLoopAgent` and `WorkflowAgent`, with typed runtime context and proposal-only default instructions. MCP is exposed as a separate server boundary for research state and evidence access. The MCP layer does **not** grant execution authority.

AI SDK 7 documents typed runtime context, tool approvals and durable `WorkflowAgent` execution as agent-runtime primitives. citeturn0search2

## Data plane: `labprobe`

`probe/cmd/labprobe` is the Go guest daemon boundary. It provides a small, dependency-free capability model for:

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

## Experiment structure: npm example

The reference recipe is `recipes/examples/npm-install.yaml`. It declares the research question, scope, compute preference, capability allowlist, intents, evidence requirements, stop conditions, and destruction rule.

The researcher workflow is:

1. **Define the question** in a contract/recipe.
2. **Validate the data model** and compile it to IR.
3. **Resolve capabilities**; unresolved capabilities are errors.
4. **Select runtime and provider** without changing the research contract.
5. **Apply policy and approvals** before execution.
6. **Create disposable compute** and place `labprobe` in the guest.
7. **Run the declared workload** such as `npm install`.
8. **Collect process/network/filesystem/syscall evidence**.
9. **Seal and hash evidence before destruction.**
10. **Analyze, independently verify, and generate a research report.**

Keep experiment definitions declarative; provider-specific implementation belongs under `src/adapters/compute/`.

## Repository layout

```text
src/
  agent/                 AI SDK 7 orchestration factories
  adapters/compute/     Compute Provider SPI + providers
  capabilities/         Capability registry/resolution
  compiler/             Recipe → IR compiler
  contract/             Research-contract checks
  gateway/              Operator HTTP boundary
  llm/                  Proposal-only reasoner
  mcp/                  MCP state/evidence server
  operations/           Operation lifecycle
  planner/              Dependency planning
  policy/               Policy and approval engine
  runtime/              Execution Runtime SPI + implementations
  state/                Research state/event model
probe/
  cmd/labprobe/         Go guest probe daemon
  internal/probe/       Probe capability model + eBPF seam
recipes/                 Declarative experiment examples
labs/                    Reference research labs
skills/
  candidate/            Experimental skills
  validated/            Reviewed skills
schema/                  Runtime schema
contracts/               Research contracts (when present)
docs/                    Architecture and researcher guides
.github/                 CI, issue templates, PR template
```

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
npx cusimanse compile recipes/examples/npm-install.yaml
```

For an actual Lima integration, use the repository's dedicated sandbox/integration workflow and ensure the host has Lima/QEMU installed. Do not interpret the mock provider as VM isolation.

## Governance

Read [`SECURITY.md`](SECURITY.md) before running untrusted workloads and [`CONTRIBUTING.md`](CONTRIBUTING.md) before submitting changes. See the Apache License 2.0 in [`LICENSE`](LICENSE).
