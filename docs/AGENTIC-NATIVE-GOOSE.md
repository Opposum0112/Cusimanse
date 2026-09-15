# Agentic native Goose branch

This branch keeps the existing Cusimanse package and reference experiments, and adds a Goose-native declarative front.

## Layers

1. LinkML + JSON Schema define contract fields.
2. `experiments/*.yaml` is the researcher program.
3. `recipes/goose/session.yaml` is the only Goose operator recipe.
4. `host-prep/default.yaml` is the declared host bootstrap catalog.
5. `cmd/compile` interprets YAML (validate / resolve / host-prep / execute plan).
6. Provision still uses the existing `cusimanse --approved run` engine until providers are fully folded into the compiler.
7. Gateway and observability stay external integrations.

## Researcher path

```bash
git checkout agentic-native-goose
./scripts/install.sh
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
go run ./cmd/compile validate npm-install-001
goose recipe validate recipes/goose/session.yaml
goose run --recipe recipes/goose/session.yaml --params experiment=npm-install-001
```

CLI without Goose:

```bash
go run ./cmd/compile validate npm-install-001
go run ./cmd/compile resolve npm-install-001
cusimanse --approved run npm-install-001
```
