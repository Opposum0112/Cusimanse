# npm installation experiment

## Purpose and scope
Observe a pinned npm project bootstrap/install inside the disposable Lima VM. Do not access unrelated host files, credentials or mounts.

## Configuration layers

```text
contract → recipes/experiments/npm-install-001.yaml → recipes/npm-install-001/recipe.yaml
```

- This contract defines purpose, scope and acceptance.
- `recipes/experiments/npm-install-001.yaml` is the Cusimanse experiment configuration.
- `recipes/npm-install-001/recipe.yaml` is the valid Goose recipe used to hand the experiment to Goose.
- `prompts/experiments/npm-install-001.md` is the cross-agent prompt handoff.

## Workload

The primary agent executes the declared workload inside the VM:

```bash
node --version
npm --version
mkdir -p /tmp/npm-test
cd /tmp/npm-test
npm init -y
npm install lodash@4.17.21 --ignore-scripts
```

The researcher launches the selected agent and reviews results; workload commands are not run manually on the host.

## Evidence

Capture command output and process, syscall, network, DNS and filesystem observations using `recipes/instrumentation/security-research.yaml`. Preserve raw evidence and SHA-256 manifests before VM destruction. Session lifecycle and artifact layout are governed by `recipes/session/session-state.yaml` and may be created/checkpointed with `scripts/session.sh`.

## Threat-model coverage and limitations

`--ignore-scripts` deliberately prevents package lifecycle scripts from running. This sample therefore does not test malicious postinstall behavior, package substitution or agent escape. Separate authorized adversarial fixtures should be added for those questions.

## Acceptance

PASS requires actual disposable-VM execution and independent verification of material findings. Missing capabilities are recorded as PARTIAL or NOT_DEPLOYED.
