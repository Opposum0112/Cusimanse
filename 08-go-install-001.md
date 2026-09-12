# 08 — go-install-001

![Experiment workflow](ai-security-lab-experiment-workflow.png)

## Purpose

Validate the complete recipe-driven Goose workflow using a pinned Go installation workload in a disposable Lima/QEMU VM.

## Recipe composition

`recipes/experiments/go-install-001.yaml` selects the workload, host profile, VM profile, tools, instrumentation, monitoring, routing, reporting and token telemetry.

## Run

Host first (once per machine):

```bash
./scripts/install.sh
source ./scripts/goose-env.sh
bash ./scripts/tests/validate-project.sh
```

Then the experiment. Use `section=project` (this chapter number is not a Goose parameter):

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

## Required evidence

- workload execution record
- process/syscall/network/filesystem evidence
- evidence hashes
- Goose/MCP/skill audit events
- forensic findings
- independent verification
- reproducibility manifest
- final report

## Acceptance

PASS requires actual runtime evidence. If MCP, a collector, a backend or another capability is unavailable, record `NOT_DEPLOYED` or `PARTIAL`; never simulate execution.
