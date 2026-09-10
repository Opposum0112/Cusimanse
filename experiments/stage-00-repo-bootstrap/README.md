# stage-00-repo-bootstrap

Repository layout bootstrap

- **Stage:** `00`
- **Document:** `03-deployment-runbook.md`
- **VM profile:** none (host-side)
- **Network policy:** `none`
- **Instrumentation:** filesystem

## Objective

Create the directory contract required by the deployment runbook.

## Hypothesis

labctl init produces a complete, hashed layout without secrets.

## Target

```bash
python3 -m labctl init
```


## Success criteria

- infra/, policies/, blackboard/, experiments/ exist
- no secret files written
- PACKAGE-MANIFEST hashes match generated files

## Procedure

1. `./scripts/bin/labctl stage run 00`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `03-deployment-runbook.md` for the authoritative procedure.
