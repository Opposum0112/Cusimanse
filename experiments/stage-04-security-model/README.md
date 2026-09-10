# stage-04-security-model

Permission tiers and mount denylist

- **Stage:** `04`
- **Document:** `04-security-model.md`
- **VM profile:** none (host-side)
- **Network policy:** `none`
- **Instrumentation:** security-events

## Objective

Encode the threat model as a local policy gate that agents can query.

## Hypothesis

Privileged operations (sudo, host mounts, credentials) default to deny.

## Target

```bash
python3 -m labctl policy check --action host-root
```


## Success criteria

- host-root denied by default
- read-tier allowed
- policy events append to JSONL

## Procedure

1. `./scripts/bin/labctl stage run 04`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `04-security-model.md` for the authoritative procedure.
