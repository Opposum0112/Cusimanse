# 08 — go-install-001

## Purpose

Validate a recipe-driven Go installation workload inside disposable Lima/QEMU compute with VM-side instrumentation, durable evidence, independent verification and a reproducible research report.

## Contract → recipe example

This is the reference example for creating a Cusimanse experiment:

- **Contract:** this file defines purpose, scope, safety, evidence and acceptance.
- **Experiment recipe:** `recipes/experiments/go-install-001.yaml` composes the host, VM, tools, instrumentation, agent, orchestration, audit, reporting and observability profiles.
- **Workload recipe:** `recipes/workloads/go-install-001.yaml` defines the exact Go workload and declares that it executes only inside disposable compute.
- **Session:** `runs/<session-id>/session.yaml` snapshots the selected profiles and tracks lifecycle state.

## Researcher execution

From the Cusimanse repository root, use the **normal host shell** for preparation and agent startup:

```bash
./scripts/cusimanse-host.sh
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
```

Start the selected primary agent, for example:

```bash
goose
```

Then give the primary agent the experiment prompt from `docs/prompts/go-install-001.md`.

The prompt causes the primary agent to validate the recipe, request approval, provision the disposable VM and start instrumentation. The actual workload is executed **inside the VM**, not on the host:

```bash
go version
go install ./packages/labprobe
```

The agent then collects evidence, delegates specialist analysis, verifies findings, writes the report, finalizes the session and destroys the VM only after evidence preservation.

## Required evidence

- workload execution record
- process/syscall/network/filesystem evidence
- evidence hashes and provenance
- agent/MCP/skill audit events when applicable
- forensic findings
- independent verification
- reproducibility manifest
- final research report
- finalized token/session dashboard snapshot

## Acceptance

PASS requires actual disposable-compute runtime evidence and independent verification. If a capability is unavailable, record `NOT_DEPLOYED` or `PARTIAL`; never simulate execution.
