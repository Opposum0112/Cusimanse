# CrewAI Integration Architecture

This document describes the `crewai` branch integration between CrewAI and Cusimanse Agent Runtime (CAR).

## Design goal

CrewAI provides agent orchestration and LLM-driven research reasoning. CAR remains the deterministic security boundary for validation, capability resolution, authorization, execution, evidence, and disposable-compute lifecycle.

```text
┌─────────────────────────────────────────────────────────────┐
│                         CrewAI                               │
│  Research Lead / Threat Researcher / Detection Engineer     │
│  Forensics Analyst / Threat Intel / Reviewer                 │
│                                                             │
│  LLM reasoning • delegation • analysis • next-step choice   │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ selects shared skill
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                  Shared CAR Skill Registry                   │
│                 skills/registry.yaml                         │
│                                                             │
│       intent vocabulary • capability refs • evidence        │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ typed declarative proposal
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    CrewAI CAR Tool Bridge                    │
│              integrations/crewai/cusimanse_tools.py          │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTP/JSON
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                        CAR Gateway                           │
│              src/integrations/crewai/server.ts               │
│                                                             │
│  proposal validation • session lookup • CAR API boundary    │
└────────────────────────────┬────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                         CAR Core                             │
│                                                             │
│ Compiler → IR → Planner → Capability Resolver               │
│                         ↓                                   │
│                  Policy + Approval                           │
│                         ↓                                   │
│                  Operation Engine                            │
│                         ↓                                   │
│                   Adapter Registry                           │
└────────────────────────────┬────────────────────────────────┘
                             │ authorized execution
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                 Research Execution Boundary                  │
│            Lima / VM / registered research tools             │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
                 Observation + Evidence + State
                             │
                             └──────────────► CrewAI
                                             next proposal
```

## Authority model

The integration deliberately separates **reasoning authority** from **execution authority**.

| Concern | CrewAI | CAR |
|---|---:|---:|
| Research reasoning | ✓ | — |
| Agent delegation | ✓ | — |
| Skill selection | ✓ | — |
| Declarative proposal | ✓ | — |
| Contract validation | — | ✓ |
| IR construction/normalization | — | ✓ |
| Capability resolution | — | ✓ |
| Policy decision | — | ✓ |
| Approval state | — | ✓ |
| Operation lifecycle | — | ✓ |
| Adapter invocation | — | ✓ |
| Evidence/provenance | — | ✓ |
| Disposable compute lifecycle | — | ✓ |

The important invariant is:

```text
CrewAI / LLM
    THINK → PLAN → PROPOSE → ANALYZE

CAR
    VALIDATE → RESOLVE → AUTHORIZE → EXECUTE
    → OBSERVE → PRESERVE → VERIFY → DESTROY
```

## Proposal lifecycle

1. A CrewAI agent selects a skill from `skills/registry.yaml`.
2. The agent/LLM converts the research need into a typed declarative proposal.
3. The Python bridge submits the proposal to CAR over HTTP.
4. `CARGateway` validates the proposal shape and identifies the research session.
5. CAR creates an execution intent from the explicit capability and parameters.
6. The normal CAR runtime resolves the capability and evaluates policy/approval.
7. Only an authorized operation can reach a registered adapter.
8. The adapter performs the operation in the declared research environment.
9. CAR records events, observations, evidence and provenance.
10. CrewAI reads state/evidence and decides whether another proposal is needed.

CrewAI never receives an API that turns a skill directly into arbitrary shell or host execution.

## Shared skill registry

The registry is deliberately independent of CrewAI so other orchestration frameworks can consume the same research vocabulary.

```text
skills/
├── registry.yaml
├── README.md
└── crewai/
    └── README.md
```

A skill identifies a CAR capability and research metadata. It is not an executable recipe.

Current references on this branch:

| Skill | CAR capability | Intended use |
|---|---|---|
| `process-observation` | `evidence.collect` | collect process/log observations |
| `network-observation` | `network.observe` | collect declared network observations |
| `npm-install-research` | `workload.npm.install` | run a declared npm workload |

The capability must be registered with CAR. Skill metadata cannot bypass CAR policy.

## Gateway contract

The gateway currently exposes three routes:

```text
POST /v1/research/{experimentId}/proposals
GET  /v1/research/{experimentId}/state
GET  /v1/research/{experimentId}/evidence
```

Example request:

```json
{
  "proposal": {
    "intent": "inspect npm install network behavior",
    "capability": "network.observe",
    "parameters": {
      "interface": "eth0",
      "duration": 60
    },
    "complete": false
  }
}
```

Executable proposals must contain an explicit `capability`. `complete: true` is treated as a terminal/no-execution proposal.

The gateway executes only the newly submitted intent rather than rerunning all previously stored intents. The submitted intent is then retained in the session IR for research history.

## Installation

### CAR

From the repository root:

```bash
npm install
npm run typecheck
npm test
```

Node.js 22 or newer is required by the package configuration.

### CrewAI

Create a Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r integrations/crewai/requirements.txt
```

Configure the gateway URL:

```bash
export CUSIMANSE_CAR_URL=http://127.0.0.1:8787
```

## Running the integration

The gateway is currently a TypeScript library. A CAR host application must create the normal `RuntimeOrchestrator`, register an experiment session, and start the gateway:

```ts
const gateway = new CARGateway(runtime);

gateway.register({
  ir: compiledResearchIr,
  state: initialResearchState,
});

gateway.listen({ host: "127.0.0.1", port: 8787 });
```

Start the CrewAI process separately and load:

```python
from integrations.crewai.cusimanse_tools import CAR_TOOLS
```

Then provide `CAR_TOOLS` to the appropriate CrewAI agents. The bridge uses the CAR URL from `CUSIMANSE_CAR_URL`.

For local development, bind the gateway to `127.0.0.1`. The current prototype does not provide authentication or durable session storage. A remote deployment therefore needs an authenticated service/control-plane boundary before exposing the gateway to agents or networks.

## Evidence and feedback loop

CAR state and evidence are read-only from the CrewAI perspective:

```text
CAR operation
     ↓
operation events
     ↓
observations
     ↓
evidence + provenance
     ↓
GET state/evidence
     ↓
CrewAI analysis
     ↓
next declarative proposal
```

This keeps the research loop agentic without moving execution authority into the orchestration framework.

## Testing boundary

`tests/crewai-gateway.test.ts` exercises the gateway boundary with a mock capability/adapter path. The integration tests verify that:

- a valid proposal reaches the runtime and adapter;
- policy denial prevents adapter execution;
- runtime events and evidence are visible through the gateway;
- an executable proposal without an explicit capability is rejected.

The tests do not require CrewAI itself to execute host operations.

## Security considerations

- Do not give CrewAI agents direct shell/subprocess access to the CAR research environment.
- Do not put host credentials into skill files or proposal parameters.
- Treat skill metadata as untrusted declarative input.
- Keep policy and approval in CAR/control-plane code.
- Keep adapters registered and capability-scoped.
- Prefer disposable compute for experiments.
- Preserve evidence and provenance before destroying disposable compute.
- Keep the prototype gateway local unless an authenticated service boundary is added.

## Current limitations

This branch is an integration prototype rather than a production multi-tenant service. Gateway sessions are in memory, the gateway has no built-in authentication, and approval remains a CAR control-plane responsibility. CrewAI is not an approval authority.
