# scripts/

The `scripts/` directory contains supporting shell utilities and validation helpers. It is **not a project controller**.

The historical Python `labctl` controller was retired during the agent-neutral refactor. Do not recreate or depend on `scripts/bin/labctl` or `scripts/labctl/`.

## Current scripts

### Installation convenience

```bash
./scripts/install.sh
```

This is currently a Goose-oriented convenience entry point because Goose is the reference adapter. Generic agents should consume `recipes/install/project-bootstrap.yaml` through their own adapter rather than adding another controller here.

### Recipe validation

```bash
bash ./scripts/tests/validate-recipes.sh
```

This parses recipe YAML and syntax-checks shell scripts.

### Full project validation

```bash
bash ./scripts/tests/validate-project.sh
```

The full validator checks recipe syntax, shell syntax, retired-controller absence, required policy files, Go formatting, Go unit tests, `policyctl` build/validation, representative policy decisions and Python unit tests when Python is available.

## Test commands

```bash
# Python tests
PYTHONPATH=scripts python3 -m unittest discover -s scripts/tests -v

# Go tests
go test ./...

# Go formatting check
gofmt -d cmd/policyctl/main.go
```

## Design rules

- Keep reusable project behavior in Markdown contracts and YAML recipes.
- Keep agent-specific behavior in adapter documentation/configuration.
- Keep `policyctl` limited to host/security policy decisions and the local token dashboard.
- Do not add a competing project controller.
- Never put credentials or sensitive telemetry into source control.
- Validation should fail clearly rather than silently downgrade missing capabilities.
