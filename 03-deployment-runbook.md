# 03 — Deployment Runbook

![Experiment workflow](ai-security-lab-experiment-workflow.png)

## Deployment model

There is one project execution model. **Goose is the reference operator/executor.** The project is agent-neutral because the contracts and recipes are independent of the agent; OpenCode, Grok Build and Antigravity can be implemented as adapters around the same model.

## 1. Prerequisites

Install/configure the selected agent. For the Goose reference path, ensure Goose, Git, Bash, Lima and QEMU are available. The selected experiment's tools recipe determines additional capabilities.

## 2. Bootstrap

From the repository root:

```bash
./scripts/install.sh
```

This convenience script performs a read-only preflight and launches `recipes/install/project-bootstrap.yaml`. It is not a project controller and does not own experiment state.

## 3. Run the complete project

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

Goose consumes the project contract and composes the modular recipes. The normal lifecycle is:

```text
discover → validate → preflight → install → plan → review → approve
→ provision → instrument → execute → collect → reduce → forensics
→ independent verification → report → preserve → destroy
```

## 4. Goose step purposes

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

## 5. Run a section while iterating

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=07
```

The same safety, policy, audit and evidence requirements apply to section execution.

## 6. Using another adapter

The adapter consumes the same project contracts and recipes. Only the agent-specific wiring changes.

```text
Markdown + YAML contracts
          ↓
     adapter layer
  ┌────────┼───────────┐
 Goose  OpenCode  Grok Build  Antigravity
  └────────┼───────────┘
          ↓
 approved tools/MCP/skills
          ↓
 Lima/QEMU + instrumentation
          ↓
 evidence + audit + verification
```

For OpenCode, Grok Build or Antigravity:

1. Load `AGENTS.md` and the relevant Markdown contract.
2. Resolve the experiment's recipe composition.
3. Map agent tools/MCP/skills to the registries.
4. Apply `policyctl` decisions and approval requirements.
5. Execute the same lifecycle and preserve the same evidence semantics.
6. Keep provider-specific prompts and wiring in the adapter.
7. Report unavailable capabilities as `NOT_DEPLOYED`.

## 7. Recipe customization

Start from the narrowest recipe family that matches the change. For example, change a workload without modifying the VM profile; change telemetry without modifying the workload.

```text
Experiment
   ↓
workload / VM / tools / install / instrumentation / monitoring
   ↓
routing / MCP / skills / stages / reporting
   ↓
experiment composition
   ↓
validate
   ↓
selected agent adapter
```

Recipe families and their purposes are documented in `recipes/README.md`. Recipes are deliberately composable rather than one large schema.

## 8. Validation

```bash
bash ./scripts/tests/validate-project.sh
```

For focused checks:

```bash
bash ./scripts/tests/validate-recipes.sh
PYTHONPATH=scripts python3 -m unittest discover -s scripts/tests -v
go test ./...
```

CI uses the project validation workflow. A failed validation must be investigated before declaring a runtime acceptance result; configuration alone is never evidence.

## 9. Token dashboard

Only `policyctl` owns the local token-usage dashboard:

```bash
./policyctl token-dashboard
```

Default binding is localhost. The dashboard is observability, not authorization.
