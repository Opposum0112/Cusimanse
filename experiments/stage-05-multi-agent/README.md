# stage-05-multi-agent

Blackboard and harness routing

- **Stage:** `05`
- **Document:** `05-multi-agent-operating-model.md`
- **VM profile:** none (host-side)
- **Network policy:** `none`
- **Instrumentation:** filesystem

## Objective

Create structured agent handoff artifacts instead of copied chat history.

## Hypothesis

A planner → reviewer → executor chain can run against blackboard files alone.

## Target

```bash
python3 -m labctl stage run 05
```


## Success criteria

- blackboard examples exist
- infra/harness-router.yaml maps each role
- findings.jsonl schema matches AGENTS.md

## Procedure

1. `./scripts/bin/labctl stage run 05`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `05-multi-agent-operating-model.md` for the authoritative procedure.
