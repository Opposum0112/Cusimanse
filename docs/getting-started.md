# Getting started

This guide is for users integrating CAR into a security-research application.

## Prerequisites

- Node.js 22 or newer
- A parsed YAML or JSON **research contract** (recipe)
- Registered CAR capabilities and adapters
- A disposable compute provider such as Lima when the experiment requires a VM

## Install

From the repository root:

```bash
npm install
```

CAR is currently exposed as a TypeScript runtime library on this branch. There is no `cusimanse` CLI entry point yet.

## Define a contract

Start with `recipes/examples/npm-install.yaml`. That file is the experiment constitution: question, non-goals, scope, capability allowlist, planned intents, required evidence, stop conditions, and destroy rules.

Read [research-contracts.md](research-contracts.md) before adding fields.

## Compile

Parse the YAML/JSON in your application and call:

```ts
const ir = compileRecipe(parsedRecipe, {
  format: "yaml",
  path: "recipes/examples/npm-install.yaml",
});
```

Compilation rejects malformed roots, missing required fields, malformed intents, intents outside `allowed_capabilities`, and unknown evidence kinds. A SHA-256 of the frozen clauses is stored on `ir.contract.hash`.

## Compose runtime dependencies

Register:

- capabilities through `CapabilityRegistry`
- policy rules through `PolicyEngine`
- approval handling through `ApprovalManager`
- operations through `OperationEngine`
- execution adapters through `AdapterRegistry`
- an optional `Reasoner`

Then create an initial state with `createResearchState(experimentId)` and call `RuntimeOrchestrator.run(ir, state)`.

Each intent is checked against the frozen contract **before** policy. A contract deny never reaches an adapter.

## Disposable experiments

For VM-backed experiments, construct `LimaLifecycle` around a `LimaProvider` implementation and use `DisposableResearchWorkflow`. The workflow owns the sequence:

```text
create → execute → observe/evidence → return result → destroy
```

If the contract sets `destroy.require_evidence_sealed: true`, a `vm.destroy` *proposal* is denied until required evidence kinds exist. The workflow `finally` block still destroys the VM when the host process ends the run — that host path is not an agent capability.

## Evidence

Use `EvidenceCollector` to record captured content:

```ts
const evidence = collector.record({
  kind: "file",
  uri: "evidence/npm-install.log",
  content: logBytes,
}, operationId);
```

The returned reference includes a SHA-256 digest, size, URI, evidence kind, experiment ID, optional operation ID, and timestamp. Persist the captured bytes and references in your evidence-storage integration before destroying disposable compute.

## Reasoning

Configure `VercelAIReasoner` with a Vercel AI SDK 7 `LanguageModel` when model-assisted research planning is useful. The model receives runtime state and returns a typed proposal. Treat that proposal as untrusted data: it must go through CAR contract evaluation, validation, planning, capability resolution, policy, approval, and operation handling before execution.
