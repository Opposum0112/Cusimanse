# Changelog

All notable changes to Cusimanse are documented here.

## [v1.0.0-beta.1] — 2026-09-11

### Added

- Agent-neutral Cusimanse project identity and documentation.
- Disposable Lima/QEMU VM experiment lifecycle.
- Modular experiment, workload, routing, installation, VM, instrumentation, monitoring, MCP, skills, audit and reporting recipes.
- Goose reference adapter with documented OpenCode, Grok Build and Antigravity adapter targets.
- `policyctl` host/security policy interface and local token-usage dashboard.
- Evidence preservation, hashing and independent-verification workflow.
- CI validation for shell syntax, ShellCheck, Go formatting, `go vet` and project validation.
- Dependabot configuration for Go modules and GitHub Actions.
- Structured bug reporting and contribution guidance.
- Reproducible source packaging with SHA-256 checksums on tagged releases.

### Security posture

- Unrestricted host mounts and host credentials remain denied by policy.
- Public MCP/gateway exposure remains denied by default.
- Privileged/destructive actions remain approval-gated.
- AI agents and policy output are not treated as isolation or evidence boundaries.

### Beta limitations

- This is a pre-production research release.
- Adapter and integration coverage is incomplete.
- Platform capability must be evaluated through the acceptance matrix rather than inferred from binary startup.
- Runtime/security capabilities must be independently exercised and evidenced.
