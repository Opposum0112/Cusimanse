# labprobe

Pinned Go module used as the **go-install-001** workload.

It prints a JSON environment snapshot and opens **no** network connections.
The interesting evidence is the `go install` process itself (module cache,
compiler, optional proxy), not this binary's runtime behavior.

## Local install (default experiment mode)

Copy this directory into the disposable VM, then:

```bash
GOPROXY=off go install .
labprobe
```

## Networked install (optional)

Only after security review, and only inside the VM:

```bash
go install github.com/Opposum0112/Cusimanse/packages/labprobe@v0.1.0
```

Use the local-copy mode for the canonical reference experiment.
