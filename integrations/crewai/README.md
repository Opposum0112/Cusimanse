# CrewAI ↔ CAR Integration (Setup B)

This directory is the **CrewAI operator**: an external process that reasons and may only call CAR over HTTP.

It is not CAR's built-in reasoner. The in-process model is `VercelAIReasoner` in `src/llm` (Setup A). How to choose and configure both: [`docs/llm.md`](../../docs/llm.md). Architecture: [`docs/crewai-architecture.md`](../../docs/crewai-architecture.md).

> **CrewAI orchestrates and reasons. CAR remains the contract, policy, and execution boundary.**

A CrewAI proposal is checked against the **frozen research contract** before policy and before any adapter.

## Architecture

```text
CrewAI Research Crew   ← each Agent has llm=LLM(...) and tools=CAR_TOOLS only
       │ roles / delegation / operator LLM
       ▼
Shared CAR Skill Registry
       │
       ▼
Typed declarative proposal
       │
       ▼
Python CAR tool bridge
       │ HTTP/JSON
       ▼
CARGateway
       │
       ▼
CAR Runtime (optional separate VercelAIReasoner is Setup A; do not dual-drive one experiment)
       ├─ contract allowlist / scope / seal / stop
       ├─ resolve capability
       ├─ policy / approval
       ├─ operation engine
       └─ adapter registry
```

CrewAI does **not** execute shell, control Lima, change policy, or receive host credentials.

## Installation

```bash
npm install && npm run typecheck && npm test
python3 -m venv .venv && source .venv/bin/activate
python -m pip install -r integrations/crewai/requirements.txt
export CUSIMANSE_CAR_URL=http://127.0.0.1:8787
```

## Start CAR

```ts
import { CARGateway } from "./src/integrations/crewai/server.js";

const gateway = new CARGateway(runtime); // omit reasoner unless you intend Setup A only
gateway.register({ ir: compiledResearchIr, state: initialResearchState });
gateway.listen({ host: "127.0.0.1", port: 8787 });
```

## Start CrewAI as operator

```python
from crewai import Agent, LLM
from integrations.crewai.cusimanse_tools import CAR_TOOLS

researcher = Agent(
    role="Threat Researcher",
    goal="Investigate the declared research question using CAR skills",
    llm=LLM(model="gpt-4.1"),
    tools=CAR_TOOLS,
    allow_delegation=False,
)
```

`CAR_TOOLS`: submit proposal, read state, read evidence. Configure the operator model on the Agent, not inside CAR.

## Gateway API

```text
POST /v1/research/{experimentId}/proposals
GET  /v1/research/{experimentId}/state
GET  /v1/research/{experimentId}/evidence
```

Off-allowlist capabilities become `not_in_contract_allowlist` and never reach an adapter.

## Limitations

In-memory sessions, no gateway auth, no CrewAI approval authority. Built-in reasoner proposals are a different path and are not auto-executed. See the root README.
