# Goose-native experiment framework

An experiment consists of a research contract plus one executable Goose recipe. The recipe packages the prompt/instructions, parameters, extensions, Skills and optional subrecipes needed for the task.

```text
contract.md
   ↓
recipe.yaml
   ↓
goose recipe validate
   ↓
goose run --recipe recipe.yaml
   ↓
evidence/ + report.md
```

The two reference experiments are `go-install-001` and `npm-install-001`. More experiments should follow the same Goose recipe format instead of introducing a parallel workflow engine.
