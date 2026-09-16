# CAR skill registry

Framework-neutral vocabulary. A skill names a capability and the **roles** that may request it. It does not execute.

```text
role → skill id → capability → proposal → CAR
```

Rules:

- No shell, credentials, or policy overrides in this file.
- Any harness reads `registry.yaml`; none own it.
- CAR policy and the experiment allowlist still decide execution.

| Skill | Capability | Roles |
|---|---|---|
| process-observation | evidence.collect | researcher, forensics-analyst, detection-engineer |
| network-observation | network.observe | network-researcher, detection-engineer, threat-researcher |
| npm-install-research | workload.npm.install | supply-chain-researcher, threat-researcher |
