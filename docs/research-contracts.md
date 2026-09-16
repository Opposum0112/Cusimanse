# Research contracts

A **research contract** is the frozen law of one experiment. Agents do not edit it. They only submit proposals that fit it.

## Four objects

| Object | File / API | Executes? |
|---|---|---|
| Contract / recipe | `recipes/*.yaml` compiled to `CusimanseIR.contract` | No |
| Skill | `skills/registry.yaml` | No |
| Proposal | `POST /v1/research/{id}/proposals` | No |
| Capability | CAR capability registry + adapter | Only after contract + policy |

Skills help an agent pick a name. The contract decides whether that name is legal *in this experiment*. Policy still has to allow it. An adapter is the only thing that touches a VM.

## Clauses the compiler understands

- `research_question` / `non_goals` — what may be asked, and what must not be pursued
- `scope` — hosts, paths, networks, disposable compute
- `allowed_capabilities` — optional allowlist. If present, static intents and later proposals must use only those names
- `intents` — the planned skeleton (`depends_on`)
- `evidence_required` — kinds that must exist before a sealed destroy
- `stop_when` — `all_evidence_required`, `max_proposals`, `max_lifetime_minutes`
- `destroy` — which capability tears the lab down, and whether evidence must be sealed first

Legacy recipes that omit `allowed_capabilities` still compile. There is then **no extra allowlist gate**. Prefer setting the list explicitly.

## Deny codes

`evaluateContractIntent` returns stable codes before policy runs:

| Code | Meaning |
|---|---|
| `not_in_contract_allowlist` | Capability is not on this contract |
| `scope_violation` | `working_directory` is outside `scope.paths` |
| `destroy_blocked_until_evidence` | Destroy requested before required evidence kinds exist |
| `max_proposals_exceeded` | Agent hit `stop_when.max_proposals` |

CrewAI cannot override these codes.

## Freeze

`compileRecipe` hashes the experiment id, intents, and contract clauses onto `contract.hash`. Treat a mid-run YAML edit as a new experiment.
