# CrewAI integration

This integration places CrewAI above CAR as a research orchestration layer.

```text
CrewAI agents
     |
     | typed research intent
     v
CrewAI CAR tools
     |
     v
CAR boundary
  validate -> resolve -> policy/approval -> operation
     |
     v
adapters -> disposable compute -> observations/evidence
```

## Install

The integration is intentionally optional. In the CrewAI environment:

```bash
pip install crewai
```

Set the URL of a CAR host exposing the integration API:

```bash
export CUSIMANSE_CAR_URL=http://127.0.0.1:8787
```

Then import the tools:

```python
from integrations.crewai.cusimanse_tools import (
    submit_research_intent,
    get_research_state,
    get_evidence,
)
```

A CrewAI agent can receive these tools and use the skill registry under
`skills/registry.yaml` as its research vocabulary.

## Security boundary

The Python bridge contains no shell, subprocess, Lima, filesystem mutation, or credential-handling code. It only submits structured requests and reads CAR-owned state/evidence. The CAR host must authenticate and authorize requests according to the deployment environment.

The HTTP paths used by the bridge are the integration contract:

- `POST /v1/research/intents`
- `GET /v1/research/{experiment_id}/state`
- `GET /v1/research/{experiment_id}/evidence`

A CAR HTTP host is the next deployment layer; this branch does not pretend that the TypeScript runtime already exposes those HTTP endpoints.
