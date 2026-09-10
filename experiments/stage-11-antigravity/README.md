# stage-11-antigravity

Antigravity workspace templates

- **Stage:** `11`
- **Document:** `11-current-antigravity-reference.md`
- **VM profile:** none (host-side)
- **Network policy:** `none`
- **Instrumentation:** filesystem

## Objective

Install project agents, skills and MCP stubs without running the upstream installer.

## Hypothesis

Workspace files can be version-controlled independently of the CLI binary.

## Target

```bash
python3 -m labctl stage run 11
```


## Success criteria

- .agents/agents and .agents/skills populated from antigravity/
- installer command printed, not executed, unless --apply --i-accept-third-party-installer

## Procedure

1. `./scripts/bin/labctl stage run 11`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `11-current-antigravity-reference.md` for the authoritative procedure.
