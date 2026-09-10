# go-install-001

Pinned Go package installation observation

- **Stage:** `08`
- **Document:** `08-go-install-001.md`
- **VM profile:** security-research
- **Network policy:** `controlled`
- **Instrumentation:** process, syscall, filesystem, dns, network, packet, security-events

## Objective

Observe a pinned in-repo Go install (packages/labprobe) inside a disposable Lima/QEMU VM.

## Hypothesis

The install produces correlated process, filesystem, DNS and network evidence that matches Go module behavior.

## Target

```bash
go install github.com/Opposum0112/ai-security-lab/packages/labprobe@v0.1.0
```


Default mode copies packages/labprobe into the VM and installs from the local path so a private GitHub repo still works. Networked module-proxy mode is opt-in.

## Success criteria

- workload ran in the disposable VM
- evidence captured, hashed, reduced
- independent verification recorded
- VM deleted after evidence preservation
- result committed to Git

## Procedure

1. `./scripts/bin/labctl stage run 08`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `08-go-install-001.md` for the authoritative procedure.
