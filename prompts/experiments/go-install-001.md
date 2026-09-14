# Go installation experiment prompt

You are the selected primary agent for the Cusimanse Go installation experiment.

Read:
- `contracts/go-install-001.md`
- `recipes/go-install-001/recipe.yaml`
- `recipes/session/session-state.yaml`

Treat the experiment recipe as authoritative. Complete the lifecycle without
asking the researcher to execute workload commands on the host. Provision the
approved disposable Lima VM, start the declared instrumentation, execute the
recipe workload inside the VM, collect evidence, delegate analysis/forensics/
verification using your native capabilities, produce the research report,
preserve provenance and destroy the VM after preservation.

Use `runs/<session-id>/session.yaml` for durable state and checkpoints. Material
findings must cite observable evidence; model output is not evidence.

After independent verification, learning is still disabled unless the researcher
explicitly sets `learning.enabled=true` and asks you to execute
`recipes/session/learning-workflow.yaml`.
