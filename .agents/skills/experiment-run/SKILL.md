---
name: experiment-run
description: Operate a Cusimanse experiment through the Go capability API in disposable compute.
---
# Experiment run
1. Read the research contract and experiment YAML.
2. Resolve requirements with `go run ./cmd/cusimanse resolve <experiment>`.
3. Obtain explicit researcher approval before approval-gated provisioning.
4. Run `go run ./cmd/cusimanse --approved run <experiment>` to provision, instrument, execute, collect and hash.
5. Analyze only preserved evidence under `runs/<session-id>/evidence/`.
6. Independently verify findings, preserve final artifacts, then destroy disposable compute.

The agent operates declared capabilities. It may select and compose registered profiles, but must not create or mutate infrastructure profiles, VM definitions or instrumentation from model output.
