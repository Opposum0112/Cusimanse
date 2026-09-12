# scripts/

The `scripts/` directory contains supporting shell utilities and validation helpers. It is **not a project controller**.

The historical Python `labctl` controller was retired during the agent-neutral refactor. Do not recreate or depend on `scripts/bin/labctl` or `scripts/labctl/`.

## Canonical host install

From the repository root:

```bash
./scripts/install.sh
source ./scripts/goose-env.sh
bash ./scripts/tests/validate-project.sh
```

`install.sh` runs `prerequisites.sh`, loads `goose-env.sh`, builds `./policyctl`, and validates policy. It does **not** launch Goose recipes or own experiment state.

Then, with Goose already configured (provider and API key stay outside the repo):

```bash
goose run --recipe recipes/install/project-bootstrap.yaml
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

Use `section=project` for the full reference lifecycle. Do not pass document numbers (`02`, `07`, `08`) as `section`.

Generic agents should consume `recipes/install/project-bootstrap.yaml` through their own adapter rather than adding another controller here.

## Recipe validation

```bash
bash ./scripts/tests/validate-recipes.sh
```

## Full project validation

```bash
bash ./scripts/tests/validate-project.sh
```

The full validator checks recipe syntax, shell syntax, retired-controller absence, required policy files, Go formatting, Go unit tests, `policyctl` build/validation, representative policy decisions and Python unit tests when Python is available.

## Test commands

```bash
# Python tests (skipped when no test_*.py modules exist)
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
