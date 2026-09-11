# Release and packaging design

## Goal

The long-term distribution artifact is a single `labctl` Go binary for Linux, macOS, and Windows where the underlying execution backend supports the requested workload.

The binary is the control plane; it does **not** embed QEMU, Lima, Docker/Podman, AI provider binaries, or third-party services. Those remain external dependencies selected by the host/backend.

## Commands

The stable interface should be:

```text
labctl doctor
labctl init
labctl preflight
labctl plan
labctl apply
labctl status
labctl experiment list
labctl experiment run <id>
labctl rollback
labctl destroy
labctl export-evidence
labctl verify
```

`plan` is read-only. `apply`, `rollback`, `destroy`, and experiment execution require explicit confirmation or `--apply` semantics.

## State and rollback

Every mutating operation should create a deployment transaction containing:

- schema/version
- host facts
- selected backend/runtime
- files changed
- hashes before/after
- processes/services started
- VM identifiers
- evidence locations
- rollback actions

Rollback must operate from this transaction instead of guessing from current state. Destructive VM deletion must occur only after evidence preservation succeeds.

## Portability model

The controller should detect OS, architecture, virtualization, container runtime, and available VM backend. Platform support is capability-based rather than OS-name based.

Initial targets:

| Platform | Controller | VM backend | Status |
|---|---|---|---|
| Linux x86_64 | Go binary | Lima/QEMU | primary |
| Linux arm64 | Go binary | Lima/QEMU when supported by image/backend | planned |
| macOS arm64 | Go binary | Lima/QEMU | planned |
| macOS x86_64 | Go binary | Lima/QEMU | planned |
| Windows | Go binary | WSL2/Hyper-V backend as implemented | planned |

The project must never report a platform as fully supported merely because the Go binary starts there.

## Reproducible releases

Release builds should use `go build` with a version injected through `-ldflags`, produce SHA-256 checksums, and publish SBOM/provenance metadata where the release pipeline supports it.

A release is not considered a deployment test. Each release must still pass the platform-specific smoke test and the repository's acceptance matrix.
