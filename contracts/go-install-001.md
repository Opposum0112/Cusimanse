# Go installation experiment

## Purpose and scope
Observe an approved Go installation and harmless local binary execution inside the disposable Lima VM. Do not access unrelated host files, credentials or mounts.

## Configuration layers

```text
contract → recipes/experiments/go-install-001.yaml → recipes/go-install-001/recipe.yaml
                                             ↘ prompts/experiments/go-install-001.md
```

- This contract defines purpose, scope and acceptance.
- `recipes/experiments/go-install-001.yaml` is the Cusimanse experiment configuration.
- `recipes/go-install-001/recipe.yaml` is the valid Goose recipe used to hand the experiment to Goose.
- `prompts/experiments/go-install-001.md` is the cross-agent prompt handoff.

The Goose recipe and prompt must not become a second configuration source. They point back to the same contract and experiment configuration.

## Runtime implementation

The deterministic execution substrate is `scripts/run-experiment.sh go-install-001`. It creates the session, validates the Lima profile, provisions the VM, starts guest collectors before the workload, executes the approved commands, captures raw evidence and writes SHA-256 manifests. It stops at `EVIDENCE_COLLECTED`; the selected primary agent owns analysis, independent verification, final reporting and the final lifecycle checkpoints.

Goose can invoke that substrate from the Goose recipe. The researcher may also use the runner directly for integration testing.

## Workload

The primary agent/runtime harness executes the declared workload inside the VM:

```bash
go version
go install ./packages/labprobe
labprobe
```

The researcher launches the selected agent and reviews results; workload commands are not run manually on the host.

## Evidence

Capture command output plus process, syscall, network and filesystem observations using `recipes/instrumentation/security-research.yaml`. Collectors start before the workload. Preserve raw evidence and SHA-256 manifests before VM destruction. Session lifecycle and artifact layout are governed by `recipes/session/session-state.yaml` and implemented by `scripts/session.sh`.

## Threat-model coverage and limitations

This sample exercises installation and local execution observation. It does not emulate malicious package behavior, agent escape or privilege escalation. Those require separate authorized adversarial fixtures; the sample must not be described as proof of those controls.

## Acceptance

PASS requires actual disposable-VM execution, complete evidence, substantive analysis, independent verification and a final researcher report. Missing capabilities are recorded as PARTIAL or NOT_DEPLOYED.
