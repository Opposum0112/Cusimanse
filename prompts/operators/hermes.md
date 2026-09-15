# Hermes adapter handoff

Use `prompts/experiments/<experiment>.md` as the agent-neutral handoff prompt.

Read the contract, experiment requirements, session-state contract and adapter matrix before planning. Native Hermes tools, Skills and delegation may support reasoning and analysis, but execution authority remains with Cusimanse's Go capability API and declared policy.

Required inputs:
- `contracts/<experiment>.md`
- `recipes/experiments/<experiment>.yaml`
- `prompts/experiments/<experiment>.md`
- `recipes/agents/adapter-matrix.yaml`

Do not mutate recipes/profiles/policy or execute the research workload directly on the host. Use Cusimanse for capability execution, honor approval gates, record unsupported capabilities as `PARTIAL`, and preserve evidence before destroy. Independent verification is required.