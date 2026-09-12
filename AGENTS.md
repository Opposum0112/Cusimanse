# AGENTS.md — Cusimanse Rules

## Mission

Build and operate a reproducible, disposable AI-assisted security research environment through declared agent adapters and modular recipes. Goose is the current reference adapter; the project is agent-neutral and may also be operated through compatible adapters such as Antigravity or Grok.

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
16. Record material MCP, skill, policy, tool and approval decisions in the audit layer.
17. Select skills only from `recipes/skills/registry.yaml`.
18. Select MCP servers only from `recipes/mcp/registry.yaml`.
19. Public reference MCP queries must not contain private workload data, secrets or credentials.
20. External reference data is enrichment, not workload evidence; record source and retrieval time.
21. Unknown or unavailable capabilities are `NOT_DEPLOYED`; never silently substitute another capability.
22. Destructive, privileged, VM-control and external-write MCP operations require explicit approval.

## Execution boundary

The selected agent adapter is the project orchestrator/operator/executor for a run. Goose is the reference adapter, while Antigravity, Grok and future compatible adapters may implement the same contracts. Skills and MCP servers provide bounded capabilities but never become a competing project controller or security boundary. `policyctl` remains limited to host/security policy configuration and the local token-usage dashboard.

## Security research workflow

`Contract → Select skills/tools → Preflight → Policy/Approval → Provision VM → Instrument → Execute → Collect → Enrich → Reduce → Verify → Report → Preserve → Destroy`

Skills should prefer deterministic local evidence collection. MCP integrations may provide repository inspection, VM control, telemetry or public-reference enrichment, but their capabilities are constrained by the registry and policy.

## Privileged operations

Treat sudo, host filesystem changes, SSH, cloud credentials, network reconfiguration, VM lifecycle control, MCP writes and destructive non-disposable changes as approval-required.

## Evidence

Claims must reference evidence. A plan, skill result, MCP response or audit event is not a substitute for workload evidence. Important findings require independent verification.

## Completion

Do not start a subsequent experiment until `go-install-001` has passed or its failure has been documented and committed.
