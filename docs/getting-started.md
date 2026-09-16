# Getting started

## Install

```bash
npm install @cusimanse/agent-runtime
```

Node.js 22+. No CrewAI dependency.

## 1. Copy a lab

Start from `labs/npm-install-day0/` (contract, policy, fixture). Read [researcher-workflow.md](researcher-workflow.md).

## 2. Compile

```ts
import { compileRecipe, createLab } from "@cusimanse/agent-runtime";

const ir = compileRecipe(parsedContract, { format: "yaml", path: "labs/npm-install-day0/contract.yaml" });
```

## 3. Attach an operator and run

```ts
createLab({
  contract: parsedContract,
  contractPath: "labs/npm-install-day0/contract.yaml",
  policy: /* rules from policy.yaml */,
  capabilities: [/* vm.create, workload.npm.install, ... */],
  adapters: [/* lima + workload adapters */],
  gateway: true,
});
```

Point any harness at `http://127.0.0.1:8787`.

## Reasoning

See [llm.md](llm.md). The built-in reasoner is optional *as a harness*. A lab created through `createLab` still needs an operator attachment.
