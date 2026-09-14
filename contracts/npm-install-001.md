# npm installation experiment

## Scope
Observe the pinned npm installation workload inside the disposable Lima VM defined by `recipes/lima/security-research.yaml`. Do not access unrelated host files, credentials or mounts.

## Workload
The experiment recipe is the authoritative executable configuration. The selected primary agent executes the workload inside the VM; the researcher only launches the agent and reviews results.

```bash
node --version
npm --version
mkdir -p /tmp/npm-test
cd /tmp/npm-test
npm init -y
npm install lodash@4.17.21 --ignore-scripts
```

Prompt handoff reference:

```text
prompts/experiments/npm-install-001.md
```

Goose can consume the recipe natively. Other validated agents can consume the same recipe through the adapter matrix and this prompt handoff without creating a second workload configuration.

## Evidence
Capture command output and process, syscall, network, DNS and filesystem observations using `recipes/instrumentation/security-research.yaml`. Preserve raw evidence and SHA-256 manifests before VM destruction.

## Acceptance
PASS requires actual disposable-VM execution and independent verification of material findings. Missing capabilities are recorded as PARTIAL or NOT_DEPLOYED.
