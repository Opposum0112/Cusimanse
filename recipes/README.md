# Recipes

Runnable workflows are `go-install-001/recipe.yaml` and `npm-install-001/recipe.yaml`. Shared subrecipes, Lima, instrumentation, host, gateway and observability profiles live beside them.

```bash
goose recipe validate recipes/go-install-001/recipe.yaml
goose recipe validate recipes/npm-install-001/recipe.yaml
goose run --recipe recipes/go-install-001/recipe.yaml --interactive
goose run --recipe recipes/npm-install-001/recipe.yaml --interactive
```
