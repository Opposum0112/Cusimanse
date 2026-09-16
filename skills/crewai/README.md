# CrewAI as CAR operator

CrewAI is an **external operator** of Cusimanse Agent Runtime. It is not the runtime.

Configure each agent's `llm=` with a CrewAI `LLM` (provider keys stay in the Python process). Attach **only** `CAR_TOOLS` from `integrations/crewai/cusimanse_tools.py`. That is Setup B in [`docs/llm.md`](../../docs/llm.md).

This is a different object from CAR's built-in `VercelAIReasoner` (Setup A). The two do not share model config. Prefer one operator per experiment.

## Mapping

| CrewAI concern | CAR responsibility |
| --- | --- |
| Agent `role` / `goal` / `backstory` | Human-written operating instructions |
| Agent `llm` | Operator model only |
| Skill selection | Capability reference on a proposal |
| `car_submit_research_proposal` | Untrusted intent for contract + policy |
| `car_get_research_state` / `car_get_evidence` | Read-only |
| Permission | CAR policy / approval |
| Execution | CAR adapter |
| Artifact | CAR evidence |

The CrewAI layer must not turn skill metadata into shell commands.

## Initial skills

- `process-observation` → `evidence.collect`
- `network-observation` → `network.observe`
- `npm-install-research` → `workload.npm.install`

Keep this registry independent of CrewAI so Setup A or another framework can use the same names.
