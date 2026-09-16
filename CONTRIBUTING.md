# Contributing

## Development

- Node.js 22 or newer.
- TypeScript is strict and production code must contain zero explicit `any` types.
- Run `npm install`, `npm run check-types`, `npm run lint`, and `npm test` before opening a pull request.
- Add or update Vitest tests for behavior changes; tests must not require external hypervisors or cloud services.
- Recipe changes must remain compatible with `schema/cusimanse-agent-runtime.yaml` and include validation coverage.

## Commits

Use Conventional Commits with prefixes such as `feat:`, `fix:`, `chore:`, and `ci:`. Every commit must contain a Developer Certificate of Origin sign-off:

`Signed-off-by: Your Name <you@example.com>`

## Pull requests

Keep security-boundary changes focused and document provider/runtime behavior. Do not commit API keys, credentials, personal files, or host-specific artifacts.
