# Cusimanse Agent Runtime (CAR)

CAR is a declarative, LLM-driven security-research runtime. An end user supplies a LinkML-governed research contract; the **mandatory LLM layer** analyzes research state and proposes typed declarative intents; CAR validates and plans those intents, resolves capabilities, applies policy and approval, executes only through registered adapters, records observations/evidence, and controls disposable compute lifecycle.

**The LLM reasons and proposes. CAR validates, authorizes, executes, observes, preserves evidence, and controls lifecycle.**

## CrewAI integration

The `crewai` branch adds an optional CrewAI orchestration boundary without making CrewAI part of CAR's execution authority:

```text
CrewAI Research Crew
        │
        │ declarative research intent
        ▼
CrewAI CAR tools
        │
        ▼
CAR Runtime
  validate → resolve → policy/approval → operation
        │
        ▼
Adapters → disposable compute → observations/evidence
        │
        ▼
CAR state/evidence → CrewAI analysis
```

CrewAI agents use the shared `skills/registry.yaml` vocabulary. Skills describe research intent and expected evidence; they are **not executable shell recipes**. The Python bridge is under `integrations/crewai/` and communicates with a CAR HTTP host. CAR remains responsible for capability resolution, authorization, execution, evidence, and lifecycle.

## Architecture

![CAR architecture](docs/architecture.svg)

The runtime is split into authority planes:

```text
Research Contract → Compiler → IR → Planner → Capability Registry
                                           ↓
                                   Policy + Approval
                                           ↓
                                   Operation Engine
                                           ↓
                                    Adapter Registry
                                           ↓
                         Lima / Shell / File / Process / npm
                                           ↓
                              Observation + Evidence
                                           ↓
                                      Runtime State
                                           ↓
                              Mandatory LLM Reasoning
                                           ↓
                              Declarative Proposal ↺
```

## Installation

For the CAR TypeScript runtime:

```bash
npm install
```

For CrewAI orchestration, install CrewAI in the Python environment used by the crew:

```bash
pip install crewai
export CUSIMANSE_CAR_URL=http://127.0.0.1:8787
```

The CrewAI bridge expects a CAR host exposing:

- `POST /v1/research/intents`
- `GET /v1/research/{experiment_id}/state`
- `GET /v1/research/{experiment_id}/evidence`

The current TypeScript runtime is still a library; an HTTP host/CLI is a separate deployment layer and is not silently claimed to exist in this branch.

## Skill registry

`skills/registry.yaml` is the framework-neutral research skill catalog. Different CrewAI crews can share it rather than inventing incompatible tool vocabularies.

```text
skills/
├── registry.yaml       # canonical skill references
├── README.md           # registry rules
└── crewai/
    └── README.md       # CrewAI role/usage guidance
```

A skill selects a CAR capability and describes parameters, expected evidence, and suitable research roles. Policy remains authoritative even when the skill metadata says approval is unnecessary.

## CrewAI tools

The bridge exposes three CAR-facing tools:

```python
from integrations.crewai.cusimanse_tools import (
    submit_research_intent,
    get_research_state,
    get_evidence,
)
```

A CrewAI researcher can submit a proposal such as:

```json
{
  "skill": "workload.npm.install",
  "intent": "install the declared npm workload in disposable research compute",
  "parameters": {
    "working_directory": "/workspace",
    "package_manager": "npm"
  },
  "complete": false
}
```

That request is data. It must cross the CAR validation, capability, planning, policy/approval and operation boundaries before execution.

## Security boundary

CrewAI is an orchestration layer, not an execution authority. The integration contains no direct shell, subprocess, Lima, or host-credential operations. CAR owns the execution path and can deny or pause an agent proposal independently of the CrewAI agent's decision.

See [`integrations/crewai/README.md`](integrations/crewai/README.md) and [`skills/registry.yaml`](skills/registry.yaml) for the integration contracts.
