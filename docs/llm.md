# Operator LLM

The model is not optional **as a product driver** when you use `createLab`: pass `reasoner` and/or `gateway: true` so *some* operator exists. The **harness** that owns the model is optional and swappable.

## Schema (required)

```ts
import { reasoningProposalSchema } from "@cusimanse/agent-runtime";
// { intent, capability?, parameters?, complete }  — strict, no command/shell keys
```

`capability` is required to execute. `complete: true` does not execute.

## In-process adapter

`VercelAIReasoner` is one optional `Reasoner`. It uses Vercel AI SDK 7 structured output. It must not call adapters.

```ts
import { VercelAIReasoner, createLab } from "@cusimanse/agent-runtime";

const reasoner = new VercelAIReasoner({ model: languageModel });
createLab({ contract, policy, capabilities, adapters, reasoner });
```

## HTTP operator

Any client POSTs the same JSON to `CARGateway`. That includes a future CrewAI example **outside** this package.

```ts
createLab({ contract, policy, capabilities, adapters, gateway: true });
```

Do not register AI-SDK or harness tools that exec, SSH, or call Lima.
