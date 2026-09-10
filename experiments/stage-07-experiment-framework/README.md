# stage-07-experiment-framework

Experiment directory contract

- **Stage:** `07`
- **Document:** `07-experiment-framework.md`
- **VM profile:** none (host-side)
- **Network policy:** `none`
- **Instrumentation:** filesystem

## Objective

Verify every experiment has the required files from doc 07.

## Hypothesis

A generator can keep 12 experiments consistent with the contract.

## Target

```bash
python3 -m labctl experiment list
```


## Success criteria

- each experiment has experiment.yaml, README, capture/run/cleanup
- VM experiments have lima.yaml

## Procedure

1. `./scripts/bin/labctl stage run 07`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `07-experiment-framework.md` for the authoritative procedure.
