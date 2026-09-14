# Goose-native deployment and runbook contract

Cusimanse has no separate deployment controller. The researcher installs/configures Goose, validates the recipe, starts a Goose session and lets Goose operate the declared workflow.

## Preparation

1. Install Goose using the official installation instructions.
2. Open this repository as the Goose working directory.
3. Review the contract and selected recipe.
4. Validate the recipe:

```bash
goose recipe validate recipes/goose/project.yaml
goose recipe validate recipes/experiments/go-install-001.yaml
goose recipe validate recipes/experiments/npm-install-001.yaml
```

## Execution

Use interactive mode for research requiring decisions:

```bash
goose run --recipe recipes/goose/project.yaml --interactive
```

Use headless mode for automation:

```bash
goose run --recipe recipes/experiments/go-install-001.yaml
```

Goose may use Developer, Skills, Summon/subrecipes, configured MCP extensions and Container Use according to the recipe and researcher configuration.

## Completion

The experiment directory contains the captured evidence and report. The researcher reviews the report, checks the verification result and preserves the artifacts. No custom VM lifecycle controller or orchestration daemon is required.
