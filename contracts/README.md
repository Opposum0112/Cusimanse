# Contracts

On `goose-native` the researcher-facing contract is the LinkML instance:

```text
schemas/cusimanse.yaml
experiments/<id>.yaml
```

Optional Markdown notes may live here as human-readable authorization copies. They are not what `go run ./cmd/cusimanse resolve` reads. Runtime requirements live in `recipes/experiments/<id>.yaml`.
