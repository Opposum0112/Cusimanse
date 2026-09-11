# AGENTS.md — AI Security Lab Rules

## Mission

Build and operate a reproducible, disposable AI-assisted security research environment operated through a declared agent adapter and configured by modular recipes. Goose is the current reference adapter; the project is agent-neutral and may also be operated through compatible adapters such as Antigravity or Grok.

## Mandatory rules

1. Read the relevant Markdown contract before changing infrastructure.
2. Use disposable Lima/QEMU VMs for untrusted experiments.
3. Never expose host credentials to experiments.
4. Never create unrestricted host filesystem mounts.
5. Do not execute unknown installers directly on the host.
6. Start instrumentation before the target action.
7. Preserve evidence before deleting VMs.
8. Do not commit secrets.
9. Use structured blackboard artifacts for agent handoffs.
10. Do not claim a component was exercised unless runtime evidence exists.
11. Do not silently bypass MCP, policy, audit or other security controls.
12. Use independent verification for important findings.
13. Record versions and reproducibility metadata.
14. Prefer deterministic data reduction before LLM analysis.
15. Treat skills as instructions, not privileges.
16. Record material MCP, skill, policy and approval decisions in the audit layer.

## Execution boundary

The selected agent adapter is the project orchestrator/operator/executor for a run. Goose is the reference adapter, while Antigravity, Grok and future compatible adapters may implement the same project contracts. Do not introduce a competing project controller. `policyctl` is limited to host/security policy configuration and the local token-usage dashboard.

## Privileged operations

Treat sudo, host filesystem changes, SSH, cloud credentials, network reconfiguration and destructive non-disposable changes as approval-required.

## Evidence

Claims must reference evidence. A plan or audit event is not a substitute for workload evidence.

## Completion

Do not start a subsequent experiment until `go-install-001` has passed or its failure has been documented and committed.
