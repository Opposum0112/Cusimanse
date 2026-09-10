# 08 — go-install-001: End-to-End Multi-Agent Integration Test

## Purpose

This is not merely a Go experiment.

It is the first end-to-end test of the complete AI security research platform.

The workload is a pinned Go package installation inside a disposable Lima/QEMU VM.

## Required architecture path

```text
User objective
→ Planner
→ Researcher
→ Builder
→ Security Reviewer
→ HarnessRouter
→ Model Gateway
→ MCP
→ Aegis
→ Numbat
→ Lima/QEMU
→ Instrumentation
→ go install
→ Evidence
→ Deterministic reduction
→ Forensics
→ Independent verification
→ Reporter
→ Git
→ Phoenix/OTel
```

If a component is not deployed, mark it as `NOT_DEPLOYED`. Never simulate usage and report it as real.

## Target

Use an explicit pinned package/version:

```bash
go install <package>@<version>
```

## Questions

Determine:
- processes created
- subprocesses
- files created/modified
- DNS queries
- domains
- IP addresses
- network connections
- downloads
- redirects
- module sources
- relevant syscalls
- unexpected behavior
- persistence or side effects

## Required artifacts

```text
blackboard/plan.json
blackboard/research.json
blackboard/security-review.json
blackboard/routing.json
blackboard/findings.jsonl
evidence/evidence-index.json
analysis/processes.json
analysis/network.json
analysis/dns.json
analysis/filesystem.json
analysis/syscalls.json
reports/go-install-001-report.md
reports/integration-scorecard.yaml
manifests/reproducibility.yaml
```

## Rules

- Start instrumentation before execution.
- Do not expose host credentials.
- Do not mount sensitive host directories.
- Preserve evidence before VM deletion.
- Reduce evidence deterministically before LLM analysis.
- Use an independent verifier.
- Do not silently bypass Aegis/Numbat/MCP controls.
- Do not proceed to another experiment until this one is complete or its failure is fully documented.

## Acceptance

The experiment passes only when:
1. the workload executed in the disposable VM;
2. evidence was captured and preserved;
3. the multi-agent workflow was exercised;
4. routing was recorded;
5. important findings were independently verified;
6. the integration scorecard was produced;
7. the reproducibility manifest was produced;
8. the VM was cleaned up;
9. the result was committed to Git.
