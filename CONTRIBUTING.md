# Contributing to Cusimanse

Thank you for contributing to Cusimanse, an agent-neutral security research platform for controlled workload detonation and evidence-driven analysis.

## Contribution types

- **Bug fixes:** include a minimal reproduction and validation evidence.
- **Documentation:** clarify contracts, runbooks, security boundaries or operator workflows.
- **Experiments/recipes:** keep recipes small, composable and reproducible.
- **Adapters:** keep Goose, OpenCode, Grok Build and Antigravity integration at the adapter boundary; do not fork experiment semantics.
- **Tests/tooling:** improve deterministic validation, evidence integrity and CI quality.

## Architecture rules

1. Keep the project recipe-driven and agent-neutral.
2. Do not introduce a second project controller.
3. Use `policyctl` only for host/security policy configuration and the local token dashboard.
4. Do not treat agents, prompts, skills, MCP servers or policy output as security boundaries.
5. Preserve VM/OS, credential, mount, network and approval controls.
6. Preserve evidence before VM destruction and hash release/runtime artifacts where required.
7. Never claim `PASS` without evidence; use `NOT_DEPLOYED` when an integration is unavailable.

## Before changing the project

1. Read `AGENTS.md` and the relevant Markdown contract.
2. Read the affected recipes and their references.
3. Keep changes reproducible and avoid secrets or unrestricted host mounts.
4. Consider both the happy path and negative/security cases.

## Local validation

```bash
./scripts/tests/validate-recipes.sh
go test ./...
go vet ./...
go build ./...
./policyctl validate
./policyctl check
bash ./scripts/tests/validate-project.sh
```

Run the checks relevant to your change and report exactly what was executed.

## Pull requests

Use a focused branch and pull request. Explain:

- what changed and why;
- architecture/security impact;
- recipes, adapters or contracts affected;
- validation performed and its result;
- platform-specific behavior;
- capabilities that remain `NOT_DEPLOYED`.

Do not include credentials, tokens, private keys, sensitive telemetry or unredacted forensic artifacts.

## Bug reports

For reproducible defects, use the GitHub **Bug Report** template. Include the smallest useful reproduction, environment details and sanitized evidence.

For potential security vulnerabilities—especially host escape, credential exposure, unsafe mounts, privilege escalation, network-policy bypass or evidence-integrity failures—**do not open a public issue**. Follow `SECURITY.md` instead.

## Code of conduct

Be respectful, precise and evidence-driven. Security research should be performed only against systems and workloads for which you have authorization.
