# 03 — Deployment Runbook

![Experiment workflow](ai-security-lab-experiment-workflow.png)

## Deployment model

There is one project execution model. **Goose is the reference operator/executor.** The project is agent-neutral because the contracts and recipes are independent of the agent; OpenCode, Grok Build and Antigravity can be implemented as adapters around the same model.

## 1. Prerequisites

From the repository root:

```bash
./scripts/install.sh
source ./scripts/goose-env.sh
```

`install.sh` installs missing host packages when possible (Git, Bash, Python 3, Go, QEMU, Lima, Goose CLI), builds `./policyctl`, and runs `policyctl validate`.

Configure the Goose model/provider and any API key in your user environment. **Do not put secrets in this repository.**

## 2. Validate (lint / policy only)

```bash
bash ./scripts/tests/validate-project.sh
```

This does not boot a VM and is not evidence that the experiment works.

## 3. Bootstrap recipes (Goose)

```bash
goose run --recipe recipes/install/project-bootstrap.yaml
```

This is a Goose recipe, not part of `install.sh`.

## 4. Run the complete project

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

Always use `section=project` for the full reference lifecycle. Goose consumes the project contract and composes the modular recipes. The normal lifecycle is:

```text
discover → validate → preflight → install → plan → review → approve
→ provision → instrument → execute → collect → reduce → forensics
→ independent verification → report → preserve → destroy
```

## 5. Goose step purposes

| Step | Purpose |
|---|---|
| Discover | resolve Markdown contracts, experiment and recipes |
| Validate | reject invalid recipe references and configuration |
| Preflight | verify required host/VM/tool capabilities |
| Install | invoke declared prerequisite installation |
| Plan | create the proposed execution sequence |
| Review | identify risky actions and required approvals |
| Approve | obtain human approval for policy-controlled operations |
| Provision | create the disposable Lima/QEMU VM |
| Instrument | start telemetry before the workload |
| Execute | perform the approved workload |
| Collect | capture runtime evidence and audit records |
| Reduce | create deterministic summaries without replacing raw evidence |
| Forensics | analyse preserved artifacts |
| Verify | independently test important findings |
| Report | generate findings and evidence manifest |
| Preserve | hash/preserve evidence before destruction |
| Destroy | delete the disposable VM after preservation |

## 6. Iterating

Re-run the same command. Do not pass `02`, `07`, or `08` as `section`; those are documentation chapter numbers, not recipe slices.

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

The same safety, policy, audit and evidence requirements apply.

## 7. Using another adapter

The adapter consumes the same project contracts and recipes. Only the agent-specific wiring changes. There is no separate installer for OpenCode, Grok Build, or Antigravity in this repository yet; treat those adapters as `NOT_DEPLOYED` until an adapter directory documents a concrete command.

```text
Markdown + YAML contracts
          ↓
     adapter layer
  ┌───────┼───────────┐
 Goose  OpenCode  Grok Build  Antigravity
  └───────┼───────────┘
          ↓
 approved tools/MCP/skills
          ↓
 Lima/QEMU + instrumentation
          ↓
 evidence + audit + verification
```

For a future adapter:

1. Load `AGENTS.md` and the relevant Markdown contract.
2. Resolve the experiment's recipe composition.
3. Map agent tools/MCP/skills to the registries.
4. Apply `policyctl` decisions and approval requirements.
5. Execute the same lifecycle and preserve the same evidence semantics.
6. Keep provider-specific prompts and wiring in the adapter.
7. Report unavailable capabilities as `NOT_DEPLOYED`.

## 8. Recipe customization

Start from the narrowest recipe family that matches the change. For example, change a workload without modifying the VM profile; change telemetry without modifying the workload.

Recipe families and their purposes are documented in `recipes/README.md`. Recipes are deliberately composable rather than one large schema.

## 9. Validation

```bash
bash ./scripts/tests/validate-project.sh
```

For focused checks:

```bash
bash ./scripts/tests/validate-recipes.sh
go test ./...
```

Python unittests run only when `scripts/tests/test_*.py` exists.

CI uses the project validation workflow. A failed validation must be investigated before declaring a runtime acceptance result; configuration alone is never evidence.

## 10. Token dashboard

Only `policyctl` owns the local token-usage dashboard:

```bash
./policyctl token-dashboard
```

Default binding is localhost. The dashboard is observability, not authorization. Build `policyctl` first (`./scripts/install.sh` or `go build -o policyctl ./cmd/policyctl`).
