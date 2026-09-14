# Go installation experiment

## Scope
Observe the approved Go installation workload inside the disposable Lima VM defined by `recipes/lima/security-research.yaml`. Do not access unrelated host files, credentials or mounts.

## Workload
The commands below are the authoritative workload definition. The **experiment recipe and primary agent execute them inside the VM**; the researcher only launches the experiment recipe and reviews the resulting evidence.

```bash
go version
go install ./packages/labprobe
```

## Evidence
Capture command output and process, syscall, network, DNS and filesystem observations using `recipes/instrumentation/security-research.yaml`. Preserve raw evidence and SHA-256 manifests before VM destruction.

## Acceptance
PASS requires actual disposable-VM execution and independent verification of material findings. Missing capabilities are recorded as PARTIAL or NOT_DEPLOYED.
