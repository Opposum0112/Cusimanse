# Release and packaging

Cusimanse uses semantic versioning with pre-release identifiers while the project is in beta.

## Current release

**v1.0.0-beta.1** — first beta release of the migrated Cusimanse project.

This release is a pre-production research release. APIs, recipes, adapters and integrations may change without backward compatibility during beta.

## Release gates

Before creating a release tag:

1. Repository validation and CI are green.
2. Go formatting, `go vet`, tests and builds pass.
3. Recipe and policy validation pass.
4. Security-sensitive changes have been reviewed.
5. Documentation and contribution/security guidance are current.
6. No credentials, private keys or sensitive runtime artifacts are included.
7. The release commit is immutable and identified by its Git tag.

A release must not be described as `PASS` for capabilities that were not actually exercised.

## Packaging

The beta release workflow creates reproducible source packages directly from the Git tag:

```text
cusimanse-v1.0.0-beta.1.tar.gz
cusimanse-v1.0.0-beta.1.zip
SHA256SUMS
```

The release package contains the source tree and documentation. It does not bundle QEMU, Lima, Goose, AI-provider binaries, credentials or third-party services.

## Release workflow

Version tags matching `v*.*.*` trigger `.github/workflows/release.yml`. The workflow:

1. checks out the exact tag;
2. verifies the checked-out commit matches the tag;
3. creates tar.gz and ZIP source archives with `git archive`;
4. generates SHA-256 checksums;
5. publishes the packages and checksums to the GitHub release.

## Beta policy

`v1.0.0-beta.*` releases are intended for authorized, controlled security research and engineering experimentation. They are not production security certifications and make no guarantee of sandbox escape resistance or completeness of integrations.

## Security and evidence

Do not package credentials, secrets, private keys or unredacted sensitive telemetry. Runtime evidence belongs in the experiment's evidence store, not in a source release.

See `SECURITY.md`, `04-security-model.md` and `10-validation-and-acceptance.md` before using or distributing a release.
