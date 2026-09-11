# 07 — Experiment Framework

![Experiment workflow](ai-security-lab-experiment-workflow.png)

## Experiment composition

An experiment is deliberately small:

```text
experiment
├── workload
├── host profile
├── VM profile
├── tools
├── instrumentation
├── agent monitoring
├── routing
├── orchestration
└── reporting
```

Do not duplicate reusable profiles unless the capability genuinely differs.

## Required properties

Every experiment is isolated, reproducible, observable, disposable, evidence-preserving and versioned.

## Baseline

Start process, network, DNS and filesystem observation before the target action.

## Execution

Run only the approved workload inside the disposable VM. Record command, timestamp, exit status and relevant telemetry.

## Cleanup

Preserve and hash evidence first. Then stop collectors, destroy the VM and verify that secrets did not enter the repository.

## First integration experiment

`go-install-001` is the reference acceptance experiment.
