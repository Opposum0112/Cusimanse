# OpenCode adapter handoff

Use the agent-neutral experiment prompt as the handoff contract:

`prompts/experiments/<experiment>.md`

Before operating, read the experiment contract, YAML requirements, session-state contract and adapter matrix. Treat the recipe/configuration as authoritative. Do not create or mutate trusted infrastructure from the prompt.

Use OpenCode's native planning, tools and delegation for research reasoning, but invoke `cusimanse` for resolve, policy-gated capability execution and lifecycle operations. Execute workloads only inside the declared disposable boundary.

Required handoff inputs:
- `contracts/<experiment>.md`
- `recipes/experiments/<experiment>.yaml`
- `prompts/experiments/<experiment>.md`
- `recipes/agents/adapter-matrix.yaml`

Record unsupported capabilities as `PARTIAL`; do not widen scope or bypass approval. Preserve evidence and provenance, require independent verification, and destroy disposable compute only after preservation.