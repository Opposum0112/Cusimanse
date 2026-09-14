# Scripts

Run everything from the repository root.

```bash
./scripts/install.sh
./scripts/preflight.sh
./scripts/tests/validate.sh
./scripts/tests/runtime.sh
```

Set `CUSIMANSE_RUN_VM_TEST=1` before `./scripts/tests/runtime.sh` to create and destroy a disposable Lima smoke-test VM.
