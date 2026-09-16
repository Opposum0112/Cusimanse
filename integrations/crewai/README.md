# CrewAI integration

CrewAI is an agent/orchestration layer above CAR. CAR remains the execution and policy boundary.

```text
CrewAI Agent
    ↓
Shared CAR Skill Registry
    ↓
Declarative proposal
    ↓ HTTP/JSON
CAR Gateway
    ↓
Validate → Resolve → Policy/Approval → Operation
    ↓
Adapter → Lima / research tool
    ↓
Evidence + State
    ↑
CrewAI reads state/evidence and reasons about the next proposal
```

## Start the CAR gateway

The gateway is a TypeScript library entry point. A host application should construct the normal CAR `RuntimeOrchestrator`, register a research session, and call `listen()`.

```ts
const gateway = new CARGateway(runtime);
gateway.register({ ir, state });
gateway.listen({ host: "127.0.0.1", port: 8787 });
```

Endpoints:

- `GET /v1/research/{experimentId}/state`
- `GET /v1/research/{experimentId}/evidence`
- `POST /v1/research/{experimentId}/proposals`

Proposal body:

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

The proposal is data. The gateway validates its shape and passes it through CAR. It does not expose an endpoint for arbitrary shell execution.

## CrewAI side

Create an isolated Python environment and install:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r integrations/crewai/requirements.txt
```

Then import `CAR_TOOLS` from `integrations/crewai/cusimanse_tools.py` into the CrewAI agent that performs the research. Set `CUSIMANSE_CAR_URL` when CAR is not using the default local address.

```python
from integrations.crewai.cusimanse_tools import CAR_TOOLS

agent = Agent(
    role="Threat Researcher",
    goal="Investigate the declared research question using CAR skills",
    tools=CAR_TOOLS,
)
```

The CrewAI agent should select registry skills and submit declarative proposals. It should not be given independent shell/subprocess tools for the same research environment.

## Security model

CrewAI can reason, delegate and analyze. CAR alone performs capability resolution, authorization and adapter execution. This separation allows multiple CrewAI crews to reuse the same CAR skill registry without creating a second execution authority.
