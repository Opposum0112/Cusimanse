# stage-09-operations

Daily operations probe

- **Stage:** `09`
- **Document:** `09-operations-and-maintenance.md`
- **VM profile:** none (host-side)
- **Network policy:** `none`
- **Instrumentation:** process, filesystem

## Objective

Inspect git, disk, VM inventory and compose health without changing the stack.

## Hypothesis

Layered troubleshooting (host → QEMU → Lima → MCP → gateway) localizes failures faster than a full restart.

## Target

```bash
python3 -m labctl doctor
```


## Success criteria

- report written under reports/
- no secrets in the report

## Procedure

1. `./scripts/bin/labctl stage run 09`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `09-operations-and-maintenance.md` for the authoritative procedure.
