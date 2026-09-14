# Goose-native validation contract

A configuration-only validation checks that every Goose recipe is valid YAML and conforms to the Goose recipe schema.

Run:

```bash
goose recipe validate recipes/goose/project.yaml
goose recipe validate recipes/experiments/go-install-001.yaml
goose recipe validate recipes/experiments/npm-install-001.yaml
```

Runtime acceptance requires an actual Goose session and evidence from the selected workload environment. Static recipe validation is not runtime proof.
