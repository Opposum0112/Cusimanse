# stage-01-architecture

Architecture plane contract

- **Stage:** `01`
- **Document:** `01-deployment-architecture.md`
- **VM profile:** none (host-side)
- **Network policy:** `none`
- **Instrumentation:** filesystem

## Objective

Confirm every architecture plane has a corresponding infra artifact.

## Hypothesis

Harness-neutral routing can be represented as committed YAML without selecting a single vendor as the security boundary.

## Target

```bash
python3 -m labctl stage run 01
```


## Success criteria

- infra/harness-router.yaml exists
- each plane listed in 01-deployment-architecture.md has a file under infra/

## Procedure

1. `./scripts/bin/labctl stage run 01`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `01-deployment-architecture.md` for the authoritative procedure.
