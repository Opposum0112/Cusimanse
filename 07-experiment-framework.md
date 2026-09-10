# 07 — Experiment Framework

## Required experiment properties

Every experiment must be:

- isolated
- reproducible
- observable
- disposable
- evidence-preserving
- versioned

## Directory

```text
experiments/<id>/
├── experiment.yaml
├── README.md
├── hypothesis.md
├── lima.yaml
├── setup.sh
├── baseline.sh
├── capture.sh
├── run.sh
├── cleanup.sh
├── analysis/
├── evidence/
├── reports/
└── manifests/
```

## Experiment manifest

Minimum fields:

```yaml
id:
name:
objective:
hypothesis:
target:
vm_profile:
network_policy:
instrumentation:
evidence:
cleanup:
success_criteria:
```

## VM profiles

Profiles should define:
- CPU
- RAM
- disk
- network
- mounts
- base image
- package sources
- evidence export method

## Baseline

Before the target action:
- collect process baseline
- collect network baseline
- collect DNS baseline
- establish filesystem baseline
- start captures

## Execution

Execute only the approved target command.

Record:
- command
- timestamp
- exit code
- stdout/stderr
- process tree
- network
- filesystem
- relevant syscalls

## Cleanup

Preserve evidence first.

Then:
- stop captures
- validate hashes
- stop VM
- delete VM
- confirm no sensitive data leaked into repository

## Reproducibility

Record:
- host
- kernel
- VM configuration
- tool versions
- target package/version
- Git commit
- evidence hashes

## First experiment

`go-install-001` is the mandatory platform integration test.
