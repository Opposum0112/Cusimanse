# scripts/

The `scripts/` directory contains supporting shell utilities and validation helpers. It is **not a project controller**.

Research semantics live in `contracts/`; declarative composition lives in `recipes/`; session state lives under `runs/<session-id>/`; the selected primary agent is the runtime operator.

The historical Python `labctl` controller was retired during the agent-neutral refactor. Do not recreate or depend on `scripts/bin/labctl` or `scripts/labctl/`.

## Canonical host install

From the repository root, use the normal host shell:

```bash
./scripts/cusimanse-host.sh
./scripts/install.sh
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

The host profile declares the host tool inventory through `recipes/host/research-host.yaml` and `recipes/tools/security-research.yaml`. Host preparation installs/preflights declared prerequisites only. It does **not** launch a research workload or become a competing lifecycle controller.

## Select and start the agent

Choose exactly one adapter through `recipes/agent-selection.yaml` and `recipes/agents/adapter-matrix.yaml`. Record the selected adapter and version in the session state.

Then start the adapter using its native command. The agent receives the experiment/session prompt and owns the lifecycle after host preparation; humans do not type every lifecycle stage as separate commands.

For the exact adapter commands, prompt and end-to-end lifecycle, use [`docs/research-workflow.md`](../docs/research-workflow.md) and [`docs/agent-shell-runbook.md`](../docs/agent-shell-runbook.md).

## Session artifacts

Every research session uses `runs/<session-id>/session.yaml` and records selected profiles, lifecycle checkpoints, approvals, audit, evidence, telemetry, verification, report, preservation, learning and token/dashboard state. Required artifacts must exist before the disposable compute is destroyed.

## Validation

```bash
bash ./scripts/tests/validate-recipes.sh
bash ./scripts/tests/validate-project.sh
./scripts/tests/production-validation.sh
```

The validators check recipe syntax, shell syntax, retired-controller absence, canonical contracts/assets, naming hygiene, policy files, session/learning contracts, Go formatting, Go tests, `policyctl` validation and representative integration assertions.

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
- Preserve and hash evidence before compute destruction.
- Finalize token accounting and the active dashboard at every session end.
- Validation should fail clearly rather than silently downgrade missing capabilities.
