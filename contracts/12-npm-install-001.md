# 12 — npm-install-001

## Purpose

Validate a recipe-driven npm installation/project bootstrap workload inside disposable Lima/QEMU compute with VM-side instrumentation, evidence preservation and independent verification.

## Contract → recipe

- **Contract:** this document defines purpose, scope, safety, evidence and acceptance.
- **Experiment recipe:** `recipes/experiments/npm-install-001.yaml` composes the selected profiles.
- **Workload recipe:** `recipes/workloads/npm-install-001.yaml` defines the exact npm commands and VM execution boundary.
- **Session:** `runs/<session-id>/session.yaml` records the selected profiles and lifecycle state.

## Researcher execution

Use the normal host shell only for host preparation, validation and primary-agent startup:

```bash
./scripts/cusimanse-host.sh
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
goose
```

Inside the selected primary agent, provide `docs/prompts/npm-install-001.md`.

The primary agent provisions the disposable compute, starts instrumentation and executes the workload inside that compute. The npm workload is never run directly on the research host.

## Workload

The workload recipe executes:

```bash
node --version
npm --version
mkdir -p /tmp/npm-test
cd /tmp/npm-test && npm init -y
cd /tmp/npm-test && npm install lodash@4.17.21 --ignore-scripts
```

Networking is controlled and package selection is pinned by the workload recipe.

## Required evidence

- workload/process execution record
- syscall/filesystem/network/DNS evidence
- package and environment versions
- evidence hashes and provenance
- audit records
- specialist findings
- independent verification
- research report
- finalized token/session dashboard snapshot

## Acceptance

PASS requires actual disposable-compute runtime evidence and independent verification. Missing capabilities are `NOT_DEPLOYED` or `PARTIAL`, never simulated.
