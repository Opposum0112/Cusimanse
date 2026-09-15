# Repository hygiene

The repository keeps source-of-truth configuration separate from generated and runtime state.

## Tracked

- Contracts, experiment configurations and Goose recipes
- Policy, capability and role/skill registries
- Host, gateway, instrumentation and observability recipes
- Go control-plane source
- Researcher/operator documentation
- Project and tool manifests

## Never commit

- `runs/<session-id>/` runtime evidence
- VM images and local Lima state
- PCAP/log/runtime scratch files
- Credentials, keys and environment secrets
- Local editor, Python and Node dependency state

These exclusions are enforced by `.gitignore`; CI validation operates on the clean repository source tree.

## Source-of-truth rule

Do not create parallel inventories or duplicate control-plane policy in documentation. Documentation explains the authoritative recipes; it does not redefine them.

Instrumentation has one dedicated researcher guide: `docs/INSTRUMENTATION.md`.
