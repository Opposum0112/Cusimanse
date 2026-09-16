# CrewAI ↔ CAR Integration

The `crewai` branch adds a narrow integration between **CrewAI** and **Cusimanse Agent Runtime (CAR)**.

> **CrewAI orchestrates and reasons. CAR remains the execution and policy boundary.**

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
       ├─ validate
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

`CARGateway` is currently a TypeScript library entry point. A host application must construct the normal CAR `RuntimeOrchestrator`, register a compiled research session, and listen:

```ts
import { CARGateway } from "./src/integrations/crewai/server.js";

const gateway = new CARGateway(runtime);

gateway.register({
  ir: compiledResearchIr,
  state: initialResearchState,
});

gateway.listen({ host: "127.0.0.1", port: 8787 });
```

The host constructs the normal CAR runtime, capability registry, policy, adapters and initial research state. The gateway does not replace those components.

For local development, keep the listener on `127.0.0.1`. The prototype has no built-in authentication; remote deployment requires an authenticated/trusted service boundary.

## Start CrewAI

Import the CAR tools into your CrewAI crew:

```python
from crewai import Agent
from integrations.crewai.cusimanse_tools import CAR_TOOLS

researcher = Agent(
    role="Threat Researcher",
    goal="Investigate the declared research question using CAR skills",
    tools=CAR_TOOLS,
)
```

The bridge provides three CAR-facing operations:

- submit a declarative research proposal;
- read research state;
- read collected evidence.

## Gateway API

```text
POST /v1/research/{experimentId}/proposals
GET  /v1/research/{experimentId}/state
GET  /v1/research/{experimentId}/evidence
```

Example proposal:

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

Executable proposals must specify `capability` explicitly. The proposal is data; it is not interpreted as shell or arbitrary host instructions. The gateway executes only the newly submitted intent, then retains it in the research session history.

## Shared skills

CrewAI uses the framework-neutral `skills/registry.yaml` catalog. Current references include:

| Skill | CAR capability | Purpose |
|---|---|---|
| `process-observation` | `evidence.collect` | process/log observation |
| `network-observation` | `network.observe` | declared network observation |
| `npm-install-research` | `workload.npm.install` | npm workload research |

Skills are declarative references, not executable recipes. CAR capability registration and policy remain authoritative.

## Recommended CrewAI roles

The shared guidance supports roles such as:

- Research Lead
- Threat Researcher
- Detection Engineer
- Forensics Analyst
- Threat Intel Analyst
- Research Reviewer

Role choice affects orchestration and skill selection; it does not grant execution privileges.

## End-to-end workflow

```text
Research contract
      ↓
CAR compiler / IR / planner
      ↓
CrewAI selects skill
      ↓
CrewAI LLM proposes intent
      ↓
CAR tool bridge
      ↓
CAR gateway
      ↓
CAR validation + capability resolution
      ↓
policy / approval
      ↓
operation + adapter
      ↓
research environment
      ↓
evidence + state
      ↓
CrewAI analysis → next proposal
```

For disposable experiments, CAR remains responsible for compute lifecycle. CrewAI should not manage the VM independently.

## Security boundary

```text
CrewAI / LLM:  THINK → PLAN → PROPOSE → ANALYZE
CAR:           VALIDATE → RESOLVE → AUTHORIZE → EXECUTE
               → OBSERVE → PRESERVE → VERIFY → DESTROY
```

The integration intentionally has no arbitrary shell endpoint and no CrewAI-facing approval authority.

## Testing

The gateway boundary is covered by `tests/crewai-gateway.test.ts`. Tests exercise successful execution through a mock adapter, policy denial, evidence/state retrieval, and rejection of executable proposals without an explicit capability.

Run:

```bash
npm test
```

## Limitations

This is currently an in-memory/library-oriented integration. Research sessions are registered by the host process, not persisted in a service database. Authentication, durable session storage, and a production deployment wrapper are outside the current gateway implementation.
