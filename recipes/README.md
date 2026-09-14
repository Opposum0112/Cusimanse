# Recipes

Experiment recipes are the authoritative executable configuration for Cusimanse.

Reference experiments:

```bash
goose recipe validate recipes/go-install-001/recipe.yaml
goose recipe validate recipes/npm-install-001/recipe.yaml
goose run --recipe recipes/go-install-001/recipe.yaml --interactive
goose run --recipe recipes/npm-install-001/recipe.yaml --interactive
```

A recipe points to the contract, host/VM/instrumentation profiles, session state,
agent adapter matrix, Goose orchestration, skills, MCP, gateways and observability.

Prompt references under `prompts/experiments/` are handoff aids for Goose or other
primary agents. They never replace or duplicate recipe configuration.
