# npm-lifecycle-001 prompt

Run the controlled Cusimanse npm lifecycle experiment.

Read first:

- `contracts/npm-lifecycle-001.md`
- `recipes/experiments/npm-lifecycle-001.yaml`
- `recipes/session/session-state.yaml`
- `recipes/instrumentation/security-research.yaml`

Operate only inside the disposable Lima VM. Use the approved local fixture under `packages/npm-fixture`; do not substitute real malware or add external network destinations.

Start instrumentation before the workload. Execute the fixture installation, capture process/syscall/filesystem/network evidence, preserve and hash the evidence, independently verify the observed postinstall behavior, and produce the researcher report.

Do not treat model output as evidence. Do not modify the contract or experiment configuration during execution. Record unavailable capabilities as `PARTIAL` rather than weakening the experiment.