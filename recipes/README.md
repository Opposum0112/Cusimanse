# Goose recipes

This directory contains **Goose-native YAML recipes**. Goose recipes are the only executable workflow configuration in the refactored project.

## Canonical recipes

- `goose/project.yaml` — reusable Cusimanse research orchestrator.
- `experiments/go-install-001.yaml` — Go reference experiment.
- `experiments/npm-install-001.yaml` — npm reference experiment.
- `goose/subrecipes/evidence-analysis.yaml` — evidence-only analysis.
- `goose/subrecipes/verification.yaml` — independent evidence verification.

Recipes use the official Goose schema: `title`, `description`, `prompt` and/or `instructions`, optional `parameters`, `extensions`, `settings` and `sub_recipes`.

## Native Goose capabilities used

- Developer tools for repository/workload commands.
- Plan/Todo for task decomposition.
- Skills through `.agents/skills/`.
- Summon and recipe subagents/subrecipes.
- MCP extensions when explicitly configured.
- Container Use for optional isolated development environments.
- Headless `goose run` for automation.
- Recipe validation with `goose recipe validate`.

## Deliberately not required

External orchestration frameworks, alternate primary-agent adapters, custom gateways, custom policy engines and custom observability controllers are not part of the Goose-native execution path.

See the official Goose recipe reference for the supported schema and validation behavior.
