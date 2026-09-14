# Goose-native Go experiment contract

## Question
Observe a Go installation workload and produce a reproducible research record.

## Scope and authorization
Run only in the researcher-selected working environment. Do not access unrelated credentials, repositories or host data.

## Workload
```bash
go version
go install ./packages/labprobe
```

The workload is executed by Goose through its Developer tools or an isolated Container Use environment selected by the researcher.

## Evidence
Preserve command output, relevant process/filesystem/network observations available through configured Goose extensions or workload tooling, file hashes where useful, and the exact recipe/contract versions.

## Acceptance
The report must distinguish observed evidence from inference. A run is complete only when the workload succeeds, evidence is preserved and important conclusions are checked independently. Missing optional tooling is reported as `NOT_DEPLOYED` rather than simulated.
