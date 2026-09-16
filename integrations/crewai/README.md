# CrewAI ↔ CAR Integration

The `crewai` branch adds a narrow integration between **CrewAI** and **Cusimanse Agent Runtime (CAR)**.

> **CrewAI orchestrates and reasons. CAR remains the contract, policy, and execution boundary.**

A CrewAI proposal is checked against the **frozen research contract** before policy and before any adapter. See [`docs/research-contracts.md`](../../docs/research-contracts.md).

## Architecture

```text
CrewAI Research Crew
       │ roles / delegation / LLM reasoning
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
CAR Runtime
       ├─ contract allowlist / scope / seal / stop
       ├─ resolve capability
       ├─ policy / approval
       ├─ operation engine
       └─ adapter registry
               │
               ▼
       Disposable compute / tools
               │
               ▼
       Evidence + Runtime State
               │
               ▼
            CrewAI → next proposal
```

CrewAI does **not** execute arbitrary shell commands, control Lima directly, change CAR policy, or receive host credentials through this integration.

## Installation

### 1. Install CAR

From the repository root, on the `crewai` branch:

```bash
npm install
npm run typecheck
npm test
```

Node.js 22+ is required.

### 2. Install CrewAI

Use an isolated Python environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r integrations/crewai/requirements.txt
```

### 3. Configure the gateway

```bash
export CUSIMANSE_CAR_URL=http://127.0.0.1:8787
```

## Start CAR

`CARGateway` is a TypeScript library entry point. A host application must construct the normal CAR `RuntimeOrchestrator`, register a **compiled contract** as the research session, and listen:

```ts
import { CARGateway } from "./src/integrations/crewai/server.js";

const gateway = new CARGateway(runtime);

gateway.register({
  ir: compiledResearchIr,
  state: initialResearchState,
});

gateway.listen({ host: "127.0.0.1", port: 8787 });
```

For local development, keep the listener on `127.0.0.1`. The prototype has no built-in authentication.

## Start CrewAI

```python
from crewai import Agent
from integrations.crewai.cusimanse_tools import CAR_TOOLS

researcher = Agent(
    role="Threat Researcher",
    goal="Investigate the declared research question using CAR skills",
    tools=CAR_TOOLS,
)
```

The bridge provides three CAR-facing operations only: submit a proposal, read state, read evidence.

## Gateway API

```text
POST /v1/research/{experimentId}/proposals
GET  /v1/research/{experimentId}/state
GET  /v1/research/{experimentId}/evidence
```

Executable proposals must specify `capability` explicitly. If the compiled IR includes `allowed_capabilities`, a name off that list is recorded as `not_in_contract_allowlist` and never reaches an adapter.

## Shared skills

| Skill | CAR capability | Purpose |
|---|---|---|
| `process-observation` | `evidence.collect` | process/log observation |
| `network-observation` | `network.observe` | declared network observation |
| `npm-install-research` | `workload.npm.install` | npm workload research |

Skills are vocabulary. The experiment contract + CAR policy remain authoritative.

## Security boundary

```text
CrewAI / LLM:  THINK → PLAN → PROPOSE → ANALYZE
CAR:           CONTRACT → VALIDATE → RESOLVE → AUTHORIZE → EXECUTE
               → OBSERVE → PRESERVE → VERIFY → DESTROY
```

## Testing

`tests/crewai-gateway.test.ts` covers successful execution, policy denial, missing capability, and allowlist denial when an adapter for the illegal capability still exists.

```bash
npm test
```

## Limitations

In-memory sessions, no gateway auth, no CrewAI approval authority. See the root README current-limitations section.
