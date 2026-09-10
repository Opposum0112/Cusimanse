# stage-10-acceptance

Seven-level acceptance matrix

- **Stage:** `10`
- **Document:** `10-validation-and-acceptance.md`
- **VM profile:** none (host-side)
- **Network policy:** `none`
- **Instrumentation:** filesystem

## Objective

Score host, execution, agent, security, model, observability and experiment levels.

## Hypothesis

NOT_DEPLOYED is a valid honest state and must not be reported as PASS.

## Target

```bash
python3 -m labctl accept
```


## Success criteria

- scorecard YAML written
- each check is PASS, PARTIAL, FAIL, or NOT_DEPLOYED

## Procedure

1. `./scripts/bin/labctl stage run 10`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `10-validation-and-acceptance.md` for the authoritative procedure.
