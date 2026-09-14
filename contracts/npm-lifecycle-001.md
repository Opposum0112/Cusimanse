# npm lifecycle behavior experiment

## Purpose
Exercise the observation pipeline against a local, harmless npm `postinstall` fixture. The fixture writes a marker under `/tmp` and attempts one localhost connection to the declared gateway port; it does not contact external hosts, read credentials or modify the host.

## Configuration

```text
contract → recipes/experiments/npm-lifecycle-001.yaml → recipes/npm-lifecycle-001/recipe.yaml
```

## Workload

Inside the disposable Lima VM, install the local fixture with lifecycle scripts enabled and inspect the resulting marker and telemetry.

## Acceptance

The run must capture the lifecycle process, filesystem marker and localhost connection attempt, preserve evidence and independently verify the observations. This is a controlled behavioral fixture, not a real malicious package.
