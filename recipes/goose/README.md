# Goose project recipe

`project.yaml` is the single entry point for project execution. It uses Goose's recipe/subrecipe model and delegates configuration to modular recipes.

## Run

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

## Run one section

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=08
```

Prerequisites are resolved first. MCP, skills and audit are selected from their registries. `policyctl` remains the separate policy and token-dashboard utility.
