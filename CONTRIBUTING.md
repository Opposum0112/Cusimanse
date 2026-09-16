# Contributing to Cusimanse

Cusimanse is an open-source, declarative security-research platform. Keep research semantics explicit, execution pluggable, and safety boundaries reviewable.

## Contribution rules

1. Keep experiment definitions declarative and reusable.
2. Keep the control plane separate from Go guest/data-plane probes.
3. Keep compute providers behind the ComputeProvider SPI.
4. Keep execution engines behind the ExecutionRuntime SPI.
5. Do not put credentials or private telemetry in Git.
6. Raw evidence must be preserved and material findings must cite it.
7. Do not describe an unexercised capability as deployed.

## Development

Requires Node.js 22+, npm, and Git. Go is required for data-plane probe work.

```bash
npm install
npm run typecheck
npm test
npm run build
```

For the reference lab:

```bash
npm run lab:npm-install
```

## Pull requests

Explain what changed, why, affected contracts/recipes, security impact, validation performed and any capability that could not be exercised.

Use Conventional Commits and sign off each commit with the DCO:

```text
git commit -s -m "feat(runtime): add ..."
```

Do not include credentials, tokens, private keys or unredacted forensic artifacts.

For potential vulnerabilities, follow `SECURITY.md` rather than publishing sensitive details in an issue.
