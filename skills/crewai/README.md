# CrewAI skill usage

CrewAI agents should treat the CAR skill registry as a capability vocabulary for research planning.

A CrewAI agent can select a skill, fill its declarative parameters, and submit a proposal to the CAR integration. The agent does not receive CAR adapter credentials or direct host execution authority.

Recommended role mapping:

- `security-researcher` — formulate hypotheses and select observation/workload skills.
- `threat-researcher` — investigate network and behavioral observations.
- `detection-engineer` — analyze telemetry and propose detection-oriented follow-up.
- `forensics-analyst` — analyze preserved process/file/log evidence.
- `supply-chain-researcher` — investigate package installation behavior.

Example proposal:

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

The CrewAI integration converts this into a CAR proposal. CAR performs the authoritative validation, capability resolution and policy/approval decision.