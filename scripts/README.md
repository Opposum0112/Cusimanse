# scripts/

The `scripts/` directory contains supporting shell utilities and validation helpers. It is **not a project controller**.

Research semantics live in `contracts/`; declarative composition lives in `recipes/`. The selected primary agent is the runtime operator.

The historical Python `labctl` controller was retired during the agent-neutral refactor. Do not recreate or depend on `scripts/bin/labctl` or `scripts/labctl/`.

## Canonical host install

From the repository root:

```bash
./scripts/cusimanse-host.sh
./scripts/install.sh
source ./scripts/goose-env.sh
bash ./scripts/tests/validate-project.sh
```

`install.sh` prepares host prerequisites, builds `./policyctl`, and validates policy. It does **not** launch a research workload or become a competing lifecycle controller.

Then, with Goose already configured (provider and API key stay outside the repo):

```bash
goose run --recipe recipes/install/project-bootstrap.yaml
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

Use `section=project` for the full reference lifecycle. Contract document numbers are not Goose `section` values.

## Validation

```bash
bash ./scripts/tests/validate-recipes.sh
bash ./scripts/tests/validate-project.sh
./scripts/tests/production-validation.sh
```

The validators check recipe syntax, shell syntax, retired-controller absence, canonical contracts/assets, naming hygiene, policy files, Go formatting, Go tests, `policyctl` validation and representative integration assertions.

## Runtime integration

A real Lima/QEMU runtime acceptance run requires a suitable research host. Hosted static CI must not be represented as VM runtime PASS.

```bash
export CUSIMANSE_LIMA_PROFILE=recipes/lima/profiles/security-research.yaml
./scripts/tests/runtime-integration.sh
./scripts/verify-run.sh reports/runtime/<run-id>
```

## Design rules

- Keep reusable project behavior in Markdown contracts and YAML recipes.
- Keep agent-specific behavior in adapter documentation/configuration.
- Keep `policyctl` limited to host/security policy decisions and the local token dashboard.
- Do not add a competing project controller.
- Never put credentials or sensitive telemetry into source control.
- Validation should fail clearly rather than silently downgrade missing capabilities.
