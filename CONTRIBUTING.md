# Contributing

Thank you for contributing to the AI Security Research Lab.

## Architecture rule

Keep the project recipe-driven and Goose-driven. Add or modify modular YAML recipes before adding code. Do not introduce a second project controller. Use `policyctl` only for host/security policy configuration.

## Before changing the project

1. Read `AGENTS.md` and the relevant Markdown contract.
2. Read `recipes/goose/project.yaml` and all recipes referenced by the change.
3. Keep changes reproducible and avoid secrets or unrestricted host mounts.
4. Clearly distinguish `PASS`, `PARTIAL`, `FAIL`, and `NOT_DEPLOYED`.

## Validation

```bash
./scripts/tests/validate-recipes.sh
go build ./cmd/policyctl
./policyctl check
```

Goose performs semantic recipe/reference validation and executes approved workflows.

## Pull requests

Explain the architecture impact, recipe changes, validation performed, platform-specific behavior, and any capabilities that remain `NOT_DEPLOYED`. Do not include credentials, tokens, private keys, or sensitive telemetry.
