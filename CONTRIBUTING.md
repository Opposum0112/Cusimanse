# Contributing to Cusimanse

Cusimanse is a declarative security-research project. Experiment semantics live in contracts and Goose-compatible recipes; Lima and the instrumentation profile provide the controlled experiment environment.

## Contribution rules

1. Keep experiment definitions declarative and reusable.
2. Keep the primary operator responsible for the lifecycle; specialist agents/subrecipes perform focused work.
3. Keep the Lima VM as the execution boundary for reference workloads.
4. Do not put credentials or private telemetry in Git.
5. Raw evidence must be preserved and material findings must cite it.
6. Independent verification is required before a material result is marked verified.
7. Do not describe an unexercised capability as deployed.

## Before changing the project

1. Read the relevant contract.
2. Read the matching Goose recipe and supporting profiles.
3. Use the single host installer when a local integration is required:

```bash
./scripts/install.sh
```

4. Run validation:

```bash
./scripts/preflight.sh
./scripts/tests/validate.sh
```

5. For Lima integration testing:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

## Pull requests

Explain what changed, why, affected contracts/recipes, security impact, validation performed and any capability that could not be exercised.

Do not include credentials, tokens, private keys or unredacted forensic artifacts.

For potential security vulnerabilities, follow `SECURITY.md` rather than publishing sensitive details in an issue.
