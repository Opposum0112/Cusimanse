# Recipes

Cusimanse separates the **Goose recipe** from the **Cusimanse experiment configuration**.

```text
recipes/<experiment>/recipe.yaml
    ↓ valid Goose handoff
recipes/experiments/<experiment>.yaml
    ↓ research requirements + policy + research metadata
recipes/profiles/registry.yaml
    ↓ compatible capabilities
cmd/cusimanse
    ↓ resolve → provision → execute → collect
Lima/QEMU disposable compute
```

Reference commands:

```bash
goose recipe validate recipes/npm-threat-001/recipe.yaml
go run ./cmd/cusimanse resolve npm-threat-001
go run ./cmd/cusimanse --approved run npm-threat-001
```

The researcher declares requirements, not infrastructure. The Goose recipe tells the selected agent how to operate the experiment. The Go capability runtime is the single implementation for profile resolution and experiment execution.
