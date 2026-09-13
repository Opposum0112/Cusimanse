# 07 — Experiment Framework

![Experiment workflow](../docs/images/cusimanse-workflow.png)

## Experiment composition

An experiment is deliberately small:

```text
experiment
├── workload
├── host profile
├── compute profile
├── tools
├── instrumentation
├── agent monitoring
├── skills
├── MCP integrations
├── reference databases
├── routing
├── orchestration
└── reporting
```

Do not duplicate reusable profiles unless the capability genuinely differs.

## Required properties

Every experiment is isolated, reproducible, observable, disposable, evidence-preserving and versioned.

## Capability contract

Each experiment must declare the capabilities it intends to use:

| Capability | Source of truth | Rule |
|---|---|---|
| Skills | `recipes/skills/registry.yaml` | reviewed instructions only |
| Tools | `recipes/tools/security-research.yaml` | declared and observable |
| MCP | `recipes/mcp/registry.yaml` | registry-approved, policy-constrained |
| Reference data | `recipes/reference/security-research-databases.yaml` | enrichment with provenance |
| Policy | `policies/host-policy.yaml` | fail closed for privileged operations |

The contract is satisfied only when the selected capability is available and its required approval has been granted. Otherwise record `NOT_DEPLOYED` or `FAIL`; never silently substitute another capability.

## Research workflow

```text
Contract
  ↓
Select skills → tools → MCP → reference sources
  ↓
Preflight + policy + approval
  ↓
Disposable compute
  ↓
Instrument → execute → collect
  ↓
Reduce → enrich → correlate
  ↓
Independent verification
  ↓
Report → preserve → destroy
```

## Reference-data rules

Reference databases can explain, enrich or prioritize an observed indicator; they cannot prove that the workload performed an action. Record source, retrieval time, query/indicator type and confidence. Do not submit secrets or private workload data to public services.

## Baseline

Start process, network, DNS and filesystem observation before the target action.

## Execution

Run only the approved workload inside the disposable VM. Record command, timestamp, exit status and relevant telemetry. Skill and MCP activity is auditable.

## Cleanup

Preserve and hash evidence first. Then stop collectors, destroy the VM and verify that secrets did not enter the repository.

## First integration experiment

`go-install-001` is the reference acceptance experiment.
