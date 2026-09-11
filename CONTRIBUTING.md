# Contributing

Thank you for contributing to the AI Security Research Lab.

## Before changing code

1. Read `AGENTS.md` and the relevant numbered deployment document.
2. Keep changes reproducible and avoid introducing secrets or unrestricted host mounts.
3. Prefer deterministic tests over tests that require external AI providers.
4. Clearly distinguish `PASS`, `PARTIAL`, `FAIL`, and `NOT_DEPLOYED`.

## Development checks

From a normal shell at the repository root:

```bash
./scripts/bin/labctl --version
./scripts/bin/labctl stages
./scripts/bin/labctl experiment list
./scripts/bin/labctl self-test
./scripts/bin/labctl init --dry-run
./scripts/bin/labctl preflight
```

Host-changing operations require explicit `--apply` and must be reviewed first.

## Agent contributions

Agents may propose or implement changes, but repository rules and human review remain authoritative. An agent must not claim that a deployment or experiment was executed unless it actually ran and the evidence was preserved.

## Pull requests

- Explain the problem and the execution environment.
- Include tests/checks performed and their results.
- Call out platform-specific behavior.
- Do not include credentials, tokens, private keys, captured secrets, or raw sensitive telemetry.
- Keep commits focused.

## Security issues

Do not disclose vulnerabilities, credentials, or sensitive evidence in public issues. Follow `SECURITY.md`.
