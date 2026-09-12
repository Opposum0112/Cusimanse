# AGENTS.md — Cusimanse Agent Rules

## Mission

Build and operate a reproducible, disposable AI-assisted security research environment through a declared primary agent adapter and modular YAML recipes. Goose is the reference adapter, not a permanent architectural dependency.

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
15. Treat skills and MCP servers as instructions/integration surfaces, not security boundaries.
16. Record material MCP, skill, policy and approval decisions in the audit layer.
17. Use `recipes/agents/primary-agent.yaml` as the common operator contract.
18. Use `recipes/agents/learning-loop.yaml` for evidence-bounded learning; no autonomous security-boundary mutation.
19. The selected primary adapter must pass preflight before a run.

## Primary operator

The primary adapter orchestrates, executes and operates the YAML-defined lifecycle. It may propose workflow improvements from verified evidence. It must not become the security boundary or independently approve privileged/destructive actions.

Allowed learning targets include non-security recipe defaults, routing hints, adapter command templates and evidence-reduction heuristics. Security boundaries, credentials, privileges, network allowlists, approval requirements and evidence-integrity rules require human-controlled change.

## Adapter model

Supported candidates include Goose, OpenCode, Grok Build, Antigravity, Pi, Codex and Prime Intellect. Enterprise candidates include Claude Code and Devin. Each adapter consumes the shared experiment semantics and must keep provider-specific wiring behind the adapter boundary.

Do not claim a provider is installed merely because its recipe exists. Missing or unavailable capabilities are `NOT_DEPLOYED`.

## Execution boundary

The selected agent adapter is the project orchestrator/operator/executor for a run. `policyctl` is limited to host/security policy configuration and the local token-usage dashboard. VM/OS, filesystem, mount, credential and network controls remain the enforcement boundary.

## Privileged operations

Treat sudo, host filesystem changes, SSH, cloud credentials, network reconfiguration and destructive non-disposable changes as approval-required.

## Evidence

Claims must reference evidence. A plan, model response or audit event is not a substitute for workload evidence.

## Completion

Do not start a subsequent experiment until the reference experiment has passed or its failure has been documented and committed.
