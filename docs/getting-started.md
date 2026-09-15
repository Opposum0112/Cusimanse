# Getting started

This guide is for users integrating CAR into a security-research application.

## Prerequisites

- Node.js 22 or newer
- A parsed YAML or JSON recipe
- Registered CAR capabilities and adapters
- A disposable compute provider such as Lima when the experiment requires a VM

## Install

From the repository root:

```bash
npm install
```

CAR is currently exposed as a TypeScript runtime library on this branch. There is no `cusimanse` CLI entry point yet.

## Define a recipe

Start with `recipes/examples/npm-install.yaml`. A recipe declares the experiment, research question, scope, operation kinds, and capability intents. Dependencies are expressed with `depends_on`.

## Compile

Parse the YAML/JSON in your application and call:

```ts
const ir = compileRecipe(parsedRecipe, {
  format: "yaml",
  path: "recipes/examples/npm-install.yaml",
});
```

Compilation rejects malformed roots, missing required fields, malformed intents, and malformed dependencies before runtime execution.

## Compose runtime dependencies

Register:

- capabilities through `CapabilityRegistry`
- policy rules through `PolicyEngine`
- approval handling through `ApprovalManager`
- operations through `OperationEngine`
- execution adapters through `AdapterRegistry`
- an optional `Reasoner`

Then create an initial state with `createResearchState(experimentId)` and call `RuntimeOrchestrator.run(ir, state)`.

## Disposable experiments

For VM-backed experiments, construct `LimaLifecycle` around a `LimaProvider` implementation and use `DisposableResearchWorkflow`. The workflow owns the sequence:

```text
create → execute → observe/evidence → return result → destroy
```

VM destruction is placed in `finally`, so cleanup runs when runtime execution fails as well as when it succeeds.

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

Configure `VercelAIReasoner` with a Vercel AI SDK 7 `LanguageModel` when model-assisted research planning is useful. The model receives runtime state and returns a typed proposal. Treat that proposal as untrusted data: it must go through CAR validation, planning, capability resolution, policy, approval, and operation handling before execution.
