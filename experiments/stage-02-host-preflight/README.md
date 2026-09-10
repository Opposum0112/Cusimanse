# stage-02-host-preflight

Host preflight

- **Stage:** `02`
- **Document:** `02-system-requirements.md`
- **VM profile:** none (host-side)
- **Network policy:** `none`
- **Instrumentation:** process, filesystem

## Objective

Measure whether the host can run one Lima VM with headroom on 16 GB RAM.

## Hypothesis

A failing preflight is more valuable than a silent install on an undersized host.

## Target

```bash
python3 -m labctl preflight
```


## Success criteria

- architecture recorded
- RAM and disk recorded
- QEMU/Lima presence recorded as PASS, PARTIAL, or NOT_DEPLOYED

## Procedure

1. `./scripts/bin/labctl stage run 02`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `02-system-requirements.md` for the authoritative procedure.
