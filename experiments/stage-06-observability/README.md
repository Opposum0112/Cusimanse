# stage-06-observability

AI and runtime observability stack

- **Stage:** `06`
- **Document:** `06-observability-and-evidence.md`
- **VM profile:** none (host-side)
- **Network policy:** `localhost-only`
- **Instrumentation:** process, network

## Objective

Stand up localhost-only Phoenix + OTel collector files and capture helpers.

## Hypothesis

Binding 127.0.0.1 prevents accidental public exposure of traces.

## Target

```bash
python3 -m labctl stack up --stack observability --dry-run
```


## Success criteria

- compose binds 127.0.0.1
- no secrets in compose files
- evidence helpers hash artifacts

## Procedure

1. `./scripts/bin/labctl stage run 06`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `06-observability-and-evidence.md` for the authoritative procedure.
