# Recipes

Cusimanse deliberately separates the **Goose recipe** from the **Cusimanse experiment configuration**.

```text
recipes/<experiment>/recipe.yaml
    ↓ valid Goose recipe: title + description + instructions/prompt
recipes/experiments/<experiment>.yaml
    ↓ experiment-specific composition and threat-model metadata
contract + host/VM/instrumentation/session/agent registries
```

Reference commands:

```bash
goose recipe validate recipes/go-install-001/recipe.yaml
goose recipe validate recipes/npm-install-001/recipe.yaml
goose run --recipe recipes/go-install-001/recipe.yaml --interactive
goose run --recipe recipes/npm-install-001/recipe.yaml --interactive
```

The Goose recipe is the native agent handoff. The companion experiment configuration is the authoritative Cusimanse composition; it is read by the agent and is not itself passed to `goose run --recipe`.

Prompt references under `prompts/experiments/` are handoff aids for Goose or other primary agents. They never replace the contract or experiment configuration.
