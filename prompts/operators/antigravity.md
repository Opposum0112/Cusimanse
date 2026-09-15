# Antigravity adapter handoff

Start from the agent-neutral prompt `prompts/experiments/<experiment>.md`.

Read the contract, YAML requirements, session-state contract and adapter matrix first. Antigravity-native agents, tools and delegation are for planning, observation and analysis; they do not grant execution authority.

Required handoff inputs:
- `contracts/<experiment>.md`
- `recipes/experiments/<experiment>.yaml`
- `prompts/experiments/<experiment>.md`
- `recipes/agents/adapter-matrix.yaml`

Invoke Cusimanse for capability resolution and execution. Never widen network, credentials, mounts or policy, mutate trusted recipes/profiles, or execute untrusted workloads on the host. Record unsupported capabilities as `PARTIAL`. Preserve and hash evidence, obtain independent verification, then complete report/preservation/destroy lifecycle.