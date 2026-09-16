# Cusimanse Agent Runtime (CAR)

CAR is a declarative, LLM-augmented security-research runtime. A research contract is compiled into normalized IR; CAR plans dependencies, resolves registered capabilities, applies policy and approval, executes only through adapters, records observations/evidence, and controls disposable research compute.

> **The LLM/CrewAI layer proposes research intent. CAR validates, authorizes, executes, observes, preserves evidence, and controls lifecycle.**

## `crewai` branch

This branch adds a **CrewAI orchestration integration** around the CAR runtime. CrewAI is intentionally outside CAR's execution authority.

```text
CrewAI Research Crew → Shared CAR Skill Registry → declarative proposal
                                      ↓
                           CrewAI CAR Tool Bridge
                                      ↓ HTTP/JSON
                                CAR Gateway
                                      ↓
                    Validate → Resolve → Policy/Approval
                                      ↓
                             Operation Engine
                                      ↓
                              Adapter Registry
                                      ↓
                    Disposable VM / research tools
                                      ↓
                           Evidence + Runtime State
                                      ↓
                                   CrewAI
```

### Authority boundary

| Layer | Responsibility | Execution authority |
|---|---|---|
| CrewAI agents | reason, delegate, select skills, analyze results | No |
| Skill registry | shared declarative research vocabulary | No |
| CAR gateway | API boundary and proposal validation | No direct host execution |
| CAR policy/approval | authorization decision | Yes |
| CAR operation engine | controlled operation lifecycle | Yes |
| CAR adapters | concrete tool/VM execution | Yes, through CAR |
| Evidence/state | provenance and research record | CAR-owned |

CrewAI should not be given a second unrestricted shell/subprocess path for the same research environment.

## Architecture

![CAR architecture](docs/architecture.svg)

The branch-specific architecture and integration sequence are documented in [`docs/crewai-architecture.md`](docs/crewai-architecture.md).

```text
Research Contract → Compiler → IR → Planner → Capability Registry
                                                ↓
                                        Policy + Approval
                                                ↓
                                        Operation Engine
                                                ↓
                                         Adapter Registry
                                                ↓
                                  Disposable Compute / Tools
                                                ↓
                                      Evidence + State
                                                ↓
                                      LLM / CrewAI reasoning
                                                ↺ proposal
```

## Repository layout

```text
src/
├── compiler/                 # contract validation / normalization
├── ir/                      # normalized research representation
├── planner/                 # deterministic dependency ordering
├── capabilities/            # capability registry / resolver
├── policy/                  # authorization + approval state
├── operations/              # controlled operation lifecycle
├── adapters/                # execution adapters
├── evidence/                # evidence + provenance
├── state/                   # research state and events
├── llm/                     # typed proposal-only LLM layer
├── runtime/                 # orchestration
└── integrations/crewai/     # TypeScript CAR/CrewAI gateway

integrations/crewai/
├── cusimanse_tools.py       # CrewAI-facing CAR tools
├── requirements.txt         # Python dependencies
└── README.md                # integration runbook

skills/
├── registry.yaml             # framework-neutral research skills
├── README.md                 # registry contract
└── crewai/README.md          # CrewAI role/usage guidance

docs/
├── architecture.svg
└── crewai-architecture.md
```

## Installation

### 1. Clone and select the branch

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout crewai
```

### 2. Install and verify CAR

CAR requires Node.js 22 or newer.

```bash
npm install
npm run typecheck
npm test
```

### 3. Install the CrewAI bridge

Use an isolated Python environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r integrations/crewai/requirements.txt
```

Set the CAR gateway address when using the default local gateway:

```bash
export CUSIMANSE_CAR_URL=http://127.0.0.1:8787
```

## Running the project with CrewAI

The current CAR gateway is a **TypeScript library entry point**, not a standalone CLI. A host process must construct the normal `RuntimeOrchestrator`, register a compiled research session, and start `CARGateway`.

```ts
import { CARGateway } from "./src/integrations/crewai/server.js";

const runtime = /* construct the normal CAR RuntimeOrchestrator */;
const gateway = new CARGateway(runtime);

gateway.register({
  ir: /* compiled/normalized CusimanseIR */,
  state: /* initial ResearchState */,
});

gateway.listen({ host: "127.0.0.1", port: 8787 });
```

Keep the gateway on `127.0.0.1` for local development. The prototype gateway has no authentication; remote deployment needs an authenticated/trusted service boundary.

In the CrewAI Python process:

```python
from crewai import Agent
from integrations.crewai.cusimanse_tools import CAR_TOOLS

researcher = Agent(
    role="Threat Researcher",
    goal="Investigate the declared research question using CAR skills",
    tools=CAR_TOOLS,
)
```

See [`integrations/crewai/README.md`](integrations/crewai/README.md) for the integration runbook and [`skills/crewai/README.md`](skills/crewai/README.md) for role/skill usage.

## CAR gateway API

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/v1/research/{experimentId}/proposals` | Submit one typed declarative proposal |
| `GET` | `/v1/research/{experimentId}/state` | Read CAR research state |
| `GET` | `/v1/research/{experimentId}/evidence` | Read collected evidence |

Example:

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

A proposal is **data, not a command**. CAR validates it, resolves the declared capability, applies policy/approval, and only then reaches an adapter. Executable proposals require an explicit `capability`.

## Shared skill registry

`skills/registry.yaml` is framework-neutral. CrewAI consumes its vocabulary, but the registry is not itself a CrewAI tool implementation.

Current references include:

- `process-observation` → `evidence.collect`
- `network-observation` → `network.observe`
- `npm-install-research` → `workload.npm.install`

Skills describe intent, roles, operation kinds, and expected evidence. CAR policy remains authoritative.

## End-to-end flow

```text
1. User declares research contract
2. CAR compiles contract → normalized IR
3. CrewAI researcher selects a shared skill
4. LLM/agent proposes typed declarative intent
5. CrewAI CAR tool submits proposal over HTTP
6. CAR validates proposal
7. CAR resolves capability + plans operation
8. CAR evaluates policy / approval
9. Authorized operation reaches registered adapter
10. Adapter executes inside the declared research boundary
11. CAR records observations, evidence and provenance
12. CrewAI reads state/evidence and proposes the next step
```

For disposable experiments, the CAR workflow remains responsible for compute creation and destruction. CrewAI does not control VM lifecycle directly.

## Security model

```text
CrewAI / LLM:  THINK → PLAN → PROPOSE → ANALYZE
CAR:           VALIDATE → RESOLVE → AUTHORIZE → EXECUTE
               → OBSERVE → PRESERVE → VERIFY → DESTROY
```

The CrewAI integration contains no arbitrary shell execution, credential access, policy mutation, or direct VM-control API.

## Current scope

This branch provides the CrewAI integration boundary, shared skill vocabulary, CAR HTTP gateway, Python tool bridge, and gateway integration tests. The gateway is currently an in-memory/library-oriented prototype: sessions are registered by the host process and are not a durable service database. Approval remains a CAR control-plane concern; CrewAI does not grant itself approval authority.
