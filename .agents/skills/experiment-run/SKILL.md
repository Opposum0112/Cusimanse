---
name: experiment-run
description: Run a Cusimanse experiment safely in disposable Lima compute.
---
# Experiment run
1. Read the contract and selected Goose recipe.
2. Run `./scripts/preflight.sh`.
3. Create the VM from `recipes/lima/security-research.yaml`.
4. Start the collectors from `recipes/instrumentation/security-research.yaml` before the workload.
5. Execute only the commands declared by the contract.
6. Store raw evidence under `runs/<session-id>/evidence/`.
7. Preserve hashes and provenance before destroying the VM.
