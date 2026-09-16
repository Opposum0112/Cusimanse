# Changelog

## Unreleased (goose-native)

### Changed

- Root README is researcher- and tester-centric: outputs, repo map, access table, npm-install-001 workflow, LinkML schema, validation gates.
- Goose recipes now call `go run ./cmd/cusimanse` only. The retired compiler CLI is no longer referenced from operator recipes, CI or inventories.
- Removed unused `internal/execution` and `internal/runtime` packages. Validation no longer depends on a missing compiler package.
- Access and observability are documented as required surfaces, with `NOT_DEPLOYED` / `PARTIAL` when a tool is absent.
- Research reports are first-class artifacts under `runs/<session-id>/research-report/`.
- Dependabot covers Go modules, `packages/labprobe`, `packages/npm-fixture` and GitHub Actions.
- Intro heading is **Cusimanse**, with an updated mascot/logo and language badges.

## v1.0.0-beta.2

### Changed

- Consolidated Cusimanse around declarative, agent-neutral experiment recipes.
- Goose is the reference primary operator; specialist work uses Goose agents and subrecipes.
- Reference experiments retain Lima/QEMU and the VM instrumentation profile.
- Host preparation is a single `./scripts/install.sh` entry point.
- LiteLLM, OmniRoute, Numbat, Aegis, Phoenix/OpenTelemetry and ClawMetry are declared mandatory host integrations.
- Reduced contracts and recipes to the experiment, subrecipe, Lima, instrumentation, host, gateway and observability definitions required by the workflow.
- Removed duplicate infrastructure, custom orchestration, alternate-agent adapter trees and the custom blackboard service.
- Simplified the researcher-facing README and evidence/report workflow.
- Added static validation and an optional disposable-Lima integration smoke test.

### Runtime status

Configuration and CI validation do not prove a successful security experiment. A runtime PASS requires actual disposable-VM execution, captured evidence and independent verification.
