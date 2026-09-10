# stage-03-runbook-stack

Lima/QEMU and container runtime files

- **Stage:** `03`
- **Document:** `03-deployment-runbook.md`
- **VM profile:** minimal
- **Network policy:** `restricted`
- **Instrumentation:** process, filesystem

## Objective

Materialize disposable VM profiles and a single container runtime choice.

## Hypothesis

Empty host mounts plus qemu vmType are enough to boot a disposable experiment VM.

## Target

```bash
python3 -m labctl stage run 03
```


## Success criteria

- infra/lima/{minimal,default,security-research}.yaml exist
- mounts: [] in every profile
- container runtime recorded in state.yaml

## Procedure

1. `./scripts/bin/labctl stage run 03`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `03-deployment-runbook.md` for the authoritative procedure.
