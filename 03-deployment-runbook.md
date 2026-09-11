# 03 — Deployment Runbook

![Experiment workflow](ai-security-lab-experiment-workflow.png)

## One-go deployment

Install/configure Goose first. Then run the project recipe from the repository root:

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

Goose resolves prerequisites before execution.

## Lifecycle

1. Discover Markdown and YAML contracts.
2. Validate recipe references.
3. Preflight the host.
4. Install declared prerequisites if required.
5. Resolve MCP, skills, audit and experiment profiles.
6. Produce the plan.
7. Obtain required approval.
8. Provision the disposable VM.
9. Start instrumentation and monitoring.
10. Execute the workload.
11. Preserve and hash evidence.
12. Reduce evidence deterministically.
13. Run forensics and independent verification.
14. Generate the report.
15. Destroy the VM after evidence preservation.

## Section execution

Run any numbered section without repeating the command model:

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=07
```

The same prerequisite and safety checks apply.

## Token dashboard

Only `policyctl` exposes the local web dashboard:

```bash
./policyctl token-dashboard
```
