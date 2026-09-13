# Cusimanse documentation

Keep documentation small and canonical:

- `architecture/` — canonical architecture diagram and Mermaid source.
- `system-requirements.md` — detailed host/runtime requirements.
- `agent-shell-runbook.md` — adapter/operator details.
- `production-architecture.md` — deployment and security-boundary model.
- `runtime-architecture.md` — execution model.
- `integration-status.md` — validation status.
- `WORKLOADS.md` — workload catalog and guidance.
- `prompts/` — only experiment-specific prompts that cannot be represented by a recipe.

Research semantics belong in `contracts/`; executable composition belongs in `recipes/`. Avoid creating duplicate workflow/runbook documents in `docs/` when the same information belongs in a contract or recipe.

## Architecture source of truth

- `architecture/cusimanse-architecture.svg` — canonical rendered architecture.
- `architecture/cusimanse-architecture.mmd` — canonical Mermaid source. It explicitly shows the researcher → contract → recipe → session → host shell → primary agent → multiagent orchestration → disposable VM → evidence → report → optional learning → dashboard/session finalization flow.

The SVG is the README architecture image; the Mermaid file is the editable architecture source.
