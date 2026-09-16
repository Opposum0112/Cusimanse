# CrewAI and reasoning architecture

This document describes how **reasoning** attaches to Cusimanse Agent Runtime (CAR) on the `crewai` branch.

CAR never gives a model execution authority. There are two operator attachments. They share one proposal schema and one runtime boundary.

```text
                    ┌── optional operators (pick one) ──┐
                    │                                │
         Setup A: CAR Reasoner            Setup B: CrewAI crew
         src/llm VercelAIReasoner         Python agents + CAR_TOOLS
         in-process after runtime.run     HTTP operator process
                    │                                │
                    └── typed proposal {intent, capability, parameters, complete}
                                      │
                                      ▼
                           CAR Gateway / RuntimeOrchestrator
                                      │
                    contract → resolve → policy → adapter → evidence
```

Full configuration examples: [`docs/llm.md`](llm.md).

## Design goal

- **Reasoning authority** may sit in CAR's optional `Reasoner` or in an external CrewAI crew.
- **Execution authority** stays in CAR: contract, capability registry, policy/approval, adapters, evidence, VM lifecycle.

CrewAI is an operator of CAR, not a replacement for it.

## Two layers in the diagram

```text
┌───────────────────────── Setup B: CrewAI operator ────────────────────────┐
│  Research Lead / Threat Researcher / Detection Engineer                 │
│  Forensics Analyst / Threat Intel / Reviewer                             │
│  Each agent: its own CrewAI LLM + only CAR_TOOLS                         │
└────────────────────────────────────────────────────────────────────┘
                             │ selects skill, POSTs proposal, GETs state
                             ▼
┌──────────────────────── Shared skill registry + proposal schema ──────────────────┐
│  skills/registry.yaml     reasoningProposalSchema (src/llm)               │
└────────────────────────────────────────────────────────────────────┘
                             │
              ┌────────────────┴────────────────┐
              ▼                                ▼
     Setup A (optional)                 CAR Gateway
     VercelAIReasoner                   src/integrations/crewai/server.ts
     called after runtime.run           validates proposal JSON
              │                                │
              └───────────────┴────────────────┘
                                      ▼
                               CAR Core
            Compiler → IR + contract.hash → Planner
                       → contract evaluate → capability resolve
                       → policy / approval → operation → adapter
                                      │
                                      ▼
                         Disposable compute + evidence
                                      │
                                      └── state/evidence ──► operators
```

## Authority model

| Concern | Built-in reasoner (A) | CrewAI operator (B) | CAR |
|---|---|---|---|
| Pick next research step | ✓ after a cycle | ✓ ongoing | — |
| Multi-agent delegation | — | ✓ | — |
| Own LLM / API key | AI SDK `LanguageModel` | CrewAI `LLM` | — |
| Submit proposal | host must re-ingest `result.proposals` | `car_submit_research_proposal` | accepts data |
| Contract / policy / adapter | — | — | ✓ |
| Approval | — | — | ✓ |
| VM lifecycle | — | — | ✓ |

```text
Operator LLM:   THINK → PLAN → PROPOSE → ANALYZE
CAR:            CONTRACT → VALIDATE → RESOLVE → AUTHORIZE → EXECUTE
                → OBSERVE → PRESERVE → VERIFY → DESTROY
```

## Proposal lifecycle (CrewAI operator)

1. Host compiles the research contract and starts `CARGateway` on `127.0.0.1`.
2. A CrewAI agent selects a skill from `skills/registry.yaml`.
3. The agent's LLM fills `{intent, capability, parameters, complete}`.
4. `cusimanse_tools.py` POSTs that object to the gateway.
5. Gateway parses it with `reasoningProposalSchema`.
6. Runtime runs contract checks, then capability + policy.
7. Only then may an adapter run.
8. Agent GETs state/evidence and proposes again or sets `complete: true`.

## Proposal lifecycle (built-in reasoner)

1. Host constructs `VercelAIReasoner({ model })` and passes it as `RuntimeOrchestrator` `reasoner`.
2. `runtime.run` executes planned contract intents first.
3. If a reasoner is configured, CAR calls `reasoner.reason(state)` once at the end of that cycle.
4. The returned proposal is stored on `result.proposals`. It is **not** auto-executed.
5. The host may submit it through the gateway or a follow-up `run` of a single intent.

That last step is intentional: the built-in layer cannot smuggle an extra execution into the same cycle.

## Configuring models

### Built-in reasoner

```ts
const reasoner = new VercelAIReasoner({
  model: yourLanguageModel, // Vercel AI SDK 7
  system: "Proposal-only CAR reasoner. Stay on the contract allowlist.",
});
```

See [`docs/llm.md`](llm.md) Setup A.

### CrewAI operator

Each `Agent(..., llm=LLM(model=...), tools=CAR_TOOLS)`. Set `CUSIMANSE_CAR_URL`. Do not attach other tools. See [`docs/llm.md`](llm.md) Setup B and [`skills/crewai/README.md`](../skills/crewai/README.md).

Do not run A and B against the same experiment without a host policy for whose proposals count toward `max_proposals`.

## Shared skill registry

The registry is independent of both operators.

| Skill | CAR capability | Intended use |
|---|---|---|
| `process-observation` | `evidence.collect` | process/log observation |
| `network-observation` | `network.observe` | declared network observation |
| `npm-install-research` | `workload.npm.install` | npm workload research |

## Gateway

```text
POST /v1/research/{experimentId}/proposals
GET  /v1/research/{experimentId}/state
GET  /v1/research/{experimentId}/evidence
```

Bind to `127.0.0.1`. No auth in this prototype.

## Testing

`tests/crewai-gateway.test.ts` and `tests/llm/reasoning.test.ts` lock the boundary: valid proposal, policy deny, missing capability, allowlist deny, schema rejects `command`.

Those tests do not call a live model and do not give CrewAI a host shell.

## Security considerations

- One execution path: CAR adapters.
- No credentials in skills, prompts, or proposal parameters.
- Approval is not an LLM tool.
- Keep both operator processes off the research VM.

## Current limitations

- Built-in reasoner proposals are not auto-applied; the host must re-ingest them.
- CrewAI and VercelAIReasoner do not share provider config.
- Gateway sessions are in-memory and unauthenticated.
- CrewAI is not an approval authority.
