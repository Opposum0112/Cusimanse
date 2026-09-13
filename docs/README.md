# Cusimanse documentation

Keep documentation small and canonical. Research semantics belong in `contracts/`; executable composition belongs in `recipes/`.

## Architecture

- `architecture/cusimanse-architecture.svg` — canonical rendered architecture.
- `architecture/cusimanse-architecture.mmd` — editable Mermaid architecture/workflow source.

The SVG and Mermaid source are the single architecture references used by the README. Do not create another architecture/workflow diagram under `docs/images/`.

## Supporting guides

- `system-requirements.md` — host and runtime requirements.
- `agent-shell-runbook.md` — adapter/operator details.
- `production-architecture.md` — deployment and security-boundary model.
- `runtime-architecture.md` — execution model.
- `integration-status.md` — validation status.
- `WORKLOADS.md` — workload catalog.
- `prompts/` — experiment-specific agent prompts only.

Avoid duplicate end-to-end workflow/runbook documents. The researcher workflow is defined by the README steps, experiment contracts and recipes; the architecture Mermaid source shows the corresponding control/data planes.
