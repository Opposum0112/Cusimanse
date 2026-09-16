# CrewAI Skill Reference

CrewAI crews should use the shared CAR skill registry as their research vocabulary.

A CrewAI agent may reason about a research task and choose a registered skill. The resulting request is converted into a CAR declarative proposal. CAR then performs capability resolution, dependency planning, policy evaluation, approval handling, execution and evidence preservation.

## Mapping

| CrewAI concern | CAR responsibility |
| --- | --- |
| Agent role | Research role |
| Skill selection | Capability reference |
| LLM reasoning | Declarative proposal |
| Tool request | CAR intent |
| Permission | Policy / approval |
| Tool execution | Adapter |
| Research artifact | Evidence |

The CrewAI layer must not turn skill metadata into arbitrary shell commands. A skill is a reference to a controlled CAR capability, not an executable script.

## Initial skills

- `process-observation` → `evidence.collect`
- `network-observation` → `network.observe`
- `npm-install-research` → `workload.npm.install`

This registry is intentionally separate from CrewAI so other agent frameworks can consume the same security-research vocabulary.
