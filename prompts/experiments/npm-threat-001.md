# npm-threat-001 experiment handoff

You are the selected primary agent for the Cusimanse npm threat research experiment.

## Read before operation

- `contracts/npm-threat-001.md`
- `recipes/experiments/npm-threat-001.yaml`
- `recipes/npm-threat-001/recipe.yaml`
- `recipes/session/session-state.yaml`
- `recipes/agents/adapter-matrix.yaml`
- `recipes/agents/goose-orchestration.yaml`

The experiment contract and requirements are authoritative. This prompt is an agent handoff, not an authority grant.

## Operator boundary

Plan and analyze with your native agent capabilities. Use registered roles/Skills and Goose Summon where supported. Invoke Cusimanse for capability resolution and execution; do not execute the workload directly on the host and do not mutate trusted recipes, profiles or policy.

Operate only inside the approved disposable Lima/QEMU boundary. Do not add credentials, external network destinations, public MCP/gateway access or real malware.

## Lifecycle

1. validate contract, requirements and recipe;
2. run native Go validation/preflight and policy checks;
3. resolve the declared experiment;
4. obtain and honor explicit researcher approval for approval-required actions;
5. provision the disposable environment and start instrumentation before workload execution;
6. execute the fixed local fixture through Cusimanse;
7. collect and hash evidence;
8. delegate specialist analysis and independent verification using registered roles/Skills;
9. generate the requirements-traceable report;
10. preserve evidence/provenance before destroy.

Material findings must cite observable preserved evidence. Model output is not evidence. If a required capability is unavailable, record `PARTIAL` rather than weakening or improvising the experiment. Learning remains disabled unless explicitly enabled through its gated workflow.