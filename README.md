# @cusimanse/agent-runtime

Harness-neutral **research-contract runtime** for agent-operated security labs.

You freeze one experiment as YAML. An operator — any harness, a built-in reasoner, or a human — may only **propose** `{ intent, capability, parameters, complete }`. CAR compiles the contract, evaluates allowlists, applies policy, runs adapters, and keeps evidence.

CrewAI is **not** part of this package. Roles and skills live in CAR YAML.

```text
harness / reasoner / human
        → proposal JSON
        → CARGateway or RuntimeOrchestrator
        → contract → policy → adapter → evidence
```

## Install

```bash
npm install @cusimanse/agent-runtime
```

From this repo (until a registry publish):

```bash
npm install github:Opposum0112/Cusimanse#crewai
```

```ts
import {
  compileRecipe,
  evaluateContractIntent,
  RuntimeOrchestrator,
  CARGateway,
  reasoningProposalSchema,
  createLab,
  VercelAIReasoner,
} from "@cusimanse/agent-runtime";
```

Node.js 22+.

## What this package is

- contract compiler + IR + planner
- `evaluateContractIntent` and deny codes
- capability / policy / operations / adapters / evidence / state
- `reasoningProposalSchema` (operator ABI payload)
- HTTP gateway: `POST /v1/research/:id/proposals`, `GET .../state`, `GET .../evidence`
- `skills/registry.yaml` (role → skill → capability)
- optional `VercelAIReasoner` that speaks the same schema
- `createLab()` host facade (requires `reasoner` and/or `gateway: true`)

## What this package is not

- a multi-agent framework
- a CrewAI wrapper
- a shell tool for models
- an approval authority the model can grant itself

## Operator vs harness

An **operator** is required to *drive* a lab through `createLab`. That operator is either:

- in-process `Reasoner` (`VercelAIReasoner` or your own), or
- any HTTP client of `CARGateway`

The **harness** (CrewAI, LangGraph, Codex, curl, a human) is swappable. It only fills the proposal schema.

```ts
createLab({
  contract: parsedYaml,
  policy: rules,
  capabilities: descriptors,
  adapters,
  gateway: true, // HTTP operator ABI on 127.0.0.1:8787
});
```

`createLab` throws `LabError` if neither `reasoner` nor `gateway: true` is set.

## Researcher workflow

Work in a **lab folder**, not a prompt dump. Gold path: [`labs/npm-install-day0/`](labs/npm-install-day0/).

Create:

| File | Purpose |
|---|---|
| `contract.yaml` | Question, non-goals, scope, allowlist, intents, evidence, stop, destroy |
| `policy.yaml` | allow / approval-required / deny |
| `fixtures/*` | Pinned subject under test |

Do not create: operator shell tools, keys in YAML, a second contract mid-run.

Full walkthrough: [`docs/researcher-workflow.md`](docs/researcher-workflow.md).

## Architecture

```text
skills/registry.yaml     roles + skill names
contract.yaml            frozen law of one experiment
        ↓
compileRecipe → IR.contract.hash
        ↓
operator proposal { intent, capability, parameters, complete }
        ↓
evaluateContractIntent → capability resolve → policy → adapter
        ↓
evidence + state (read-only to the operator)
```

See [`docs/architecture.md`](docs/architecture.md).

## HTTP operator ABI

```text
POST /v1/research/{experimentId}/proposals
GET  /v1/research/{experimentId}/state
GET  /v1/research/{experimentId}/evidence
```

```json
{
  "proposal": {
    "intent": "inspect npm install network behavior",
    "capability": "network.observe",
    "parameters": { "interface": "eth0", "duration": 60 },
    "complete": false
  }
}
```

Bind to `127.0.0.1`. This prototype has no authentication.

## Deny codes

- `not_in_contract_allowlist`
- `scope_violation`
- `destroy_blocked_until_evidence`
- `max_proposals_exceeded`

## Layout

```text
src/compiler contract ir planner capabilities policy operations
    adapters evidence state llm gateway lab
labs/npm-install-day0/
skills/registry.yaml
```

## Tests

```bash
npm test
```
