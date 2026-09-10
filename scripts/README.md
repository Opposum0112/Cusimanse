# scripts/ — labctl

Python 3.10+ control plane for this repository. **No third-party Python
packages.** It materializes the infrastructure stack and one experiment per
document stage (01–11 plus runbook bootstrap).

The in-repo Go module [`packages/labprobe`](../packages/labprobe) is the
pinned target for `go-install-001`.

Host install (clone, apt, Lima, first `labctl` run) is documented in the
root [README Installation](../README.md#installation) section.

## Commands

```bash
./scripts/bin/labctl stages          # document → stage map
./scripts/bin/labctl init            # write infra/, experiments/, policies/
./scripts/bin/labctl preflight       # host checks (doc 02)
./scripts/bin/labctl preflight --apply
./scripts/bin/labctl stage run 04    # security model files + policy probe
./scripts/bin/labctl experiment list
./scripts/bin/labctl experiment run go-install-001
./scripts/bin/labctl experiment run go-install-001 --apply
./scripts/bin/labctl stack up observability --apply
./scripts/bin/labctl accept          # seven-level matrix (doc 10)
./scripts/bin/labctl doctor
./scripts/bin/labctl policy check --action host-root
```

`init` and `stage` write repository files by default (idempotent). Anything
that starts a process, records live host state, appends the event log, or
executes an experiment script requires `--apply`.

`labctl` will **not** pipe `curl | bash` for Antigravity or any other
installer.

## Stage map

| ID | Stage | Document | Experiment |
|---|---|---|---|
| 00 | repo-bootstrap | 03-deployment-runbook.md | stage-00-repo-bootstrap |
| 01 | architecture | 01-deployment-architecture.md | stage-01-architecture |
| 02 | host-preflight | 02-system-requirements.md | stage-02-host-preflight |
| 03 | runbook-stack | 03-deployment-runbook.md | stage-03-runbook-stack |
| 04 | security-model | 04-security-model.md | stage-04-security-model |
| 05 | multi-agent | 05-multi-agent-operating-model.md | stage-05-multi-agent |
| 06 | observability | 06-observability-and-evidence.md | stage-06-observability |
| 07 | experiment-framework | 07-experiment-framework.md | stage-07-experiment-framework |
| 08 | go-install-001 | 08-go-install-001.md | go-install-001 |
| 09 | operations | 09-operations-and-maintenance.md | stage-09-operations |
| 10 | acceptance | 10-validation-and-acceptance.md | stage-10-acceptance |
| 11 | antigravity | 11-current-antigravity-reference.md | stage-11-antigravity |

## Safety

- Lima profiles use `mounts: []`
- Compose stacks bind `127.0.0.1` only
- Privileged policy actions default to **deny**
- Secrets stay in gitignored `*.env` files copied from `*.env.example`

## Tests

```bash
PYTHONPATH=scripts python3 -m unittest discover -s scripts/tests -v
```
