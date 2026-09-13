# go-install-001

Pinned Go package installation observation

- **Stage:** `08`
- **Contract:** `contracts/08-go-install-001.md`
- **Experiment recipe:** `recipes/experiments/go-install-001.yaml`
- **Workload:** `recipes/workloads/go-install-001.yaml`
- **VM profile:** `recipes/lima/profiles/security-research.yaml`
- **Network policy:** `controlled`
- **Instrumentation:** process, syscall, filesystem, dns, network, packet, security-events

## Objective

Observe a pinned in-repo Go install (`packages/labprobe`) inside a disposable Lima/QEMU VM.

## Hypothesis

The install produces correlated process, filesystem, DNS and network evidence that matches Go module behavior.

## Target

```bash
go version
go install ./packages/labprobe
```

The reference workload uses the local module path so it is self-contained and does not depend on a remote repository. Networked module-proxy behavior is a separate, explicitly declared experiment variant.

## Success criteria

- workload ran in the disposable VM
- evidence captured, hashed, reduced
- independent verification recorded
- VM deleted after evidence preservation
- result committed to Git

## Procedure

1. Validate the contract and experiment/workload recipes.
2. Start capture **before** the target command.
3. Execute the declared workload only inside disposable compute.
4. Preserve and hash evidence before deleting the VM.
5. Do not mount host credentials.

The contract and recipes are authoritative; this file is only a concise experiment reference.
