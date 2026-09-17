# Changelog

## Unreleased — adk-cusimanse

### Changed

- Native Go security research agent built on Google ADK Go 2.
- ADK owns reasoning and workflow orchestration; Cusimanse remains the execution authority.
- Added a bounded adaptive research workflow with plan → research → analysis → verification → acceptance routing.
- Added persistent ADK session storage for resumable research sessions.
- Added a crash-safe execution journal with deterministic operation IDs.
- Capability execution now refuses blind replay of unresolved or ambiguous effects and returns completed results for safe idempotent replay.
- Removed legacy Goose agent/runtime scaffolding from this branch while retaining reusable research skills.
- README and architecture documentation are oriented around end-user testing and the researcher workflow.

### Runtime status

The branch is under active implementation and validation. A successful build or model response is not itself a security finding. A research PASS requires preserved evidence and independent verification.

## v1.0.0-beta.2

### Changed

- Consolidated Cusimanse around declarative, agent-neutral experiment recipes.
- Goose was the reference primary operator; specialist work used Goose agents and subrecipes.
- Reference experiments retain Lima/QEMU and the VM instrumentation profile.
- Host preparation is a single `./scripts/install.sh` entry point.
- LiteLLM, OmniRoute, Numbat, Aegis, Phoenix/OpenTelemetry and ClawMetry were declared mandatory host integrations.
- Reduced contracts and recipes to the experiment, subrecipe, Lima, instrumentation, host, gateway and observability definitions required by the workflow.
- Removed duplicate infrastructure, custom orchestration, alternate-agent adapter trees and the custom blackboard service.
- Simplified the researcher-facing README and evidence/report workflow.
- Added static validation and an optional disposable-Lima integration smoke test.

### Runtime status

Configuration and CI validation do not prove a successful security experiment. A runtime PASS requires actual disposable-VM execution, captured evidence and independent verification.
