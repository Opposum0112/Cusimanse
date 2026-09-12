# AGENTS.md — Cusimanse Rules

## Mission

Build and operate a reproducible, disposable AI-assisted security research environment through declared agent adapters and modular recipes. Goose is the current reference adapter; specialist roles, skills, MCP capabilities and security frameworks support research but never replace project security controls.

## Mandatory rules

1. Read the relevant Markdown contract before changing infrastructure.
2. Use disposable Lima/QEMU VMs for untrusted experiments.
3. Never expose host credentials to experiments or MCP arguments.
4. Never create unrestricted host filesystem mounts.
5. Do not execute unknown installers directly on the host.
6. Start instrumentation before the target action.
7. Preserve and hash evidence before deleting VMs.
8. Do not commit secrets.
9. Use structured blackboard artifacts for agent handoffs.
10. Do not claim a component was exercised unless runtime evidence exists.
11. Do not silently bypass MCP, policy, audit or approval controls.
12. Use independent verification for important findings and detections.
13. Record versions, provenance and reproducibility metadata.
14. Prefer deterministic data reduction before LLM analysis.
15. Treat skills as instructions, not privileges.
16. Record material MCP, skill, policy, tool, framework and approval decisions in the audit layer.
17. Select skills only from `recipes/skills/registry.yaml`.
18. Select MCP servers only from `recipes/mcp/registry.yaml`.
19. Public reference MCP queries must not contain private workload data, secrets or credentials.
20. External reference data is enrichment, not workload evidence; record source and retrieval time.
21. Unknown or unavailable capabilities are `NOT_DEPLOYED`; never silently substitute another capability.
22. Destructive, privileged, VM-control and external-write MCP operations require explicit approval.
23. Detection validation must use captured evidence or an explicitly authorized test corpus.

## Security-research roles

Use composable roles as needed: Planner, Threat Modeler, Security Reviewer, Static Analyst, Dynamic/Runtime Analyst, Network Analyst, Malware Analyst, Reverse Engineer, Threat Intelligence Analyst, Detection Engineer, Forensics Analyst, Vulnerability Researcher, Supply-chain Analyst, Independent Verifier and Reporter.

Roles are not separate controllers. CrewAI may coordinate specialist roles, but Goose remains the project operator, executor and lifecycle authority.

## Security frameworks

Use `recipes/reference/security-frameworks.yaml` to map research to appropriate frameworks such as MITRE ATT&CK/ATLAS, NIST CSF and testing guidance, CIS Controls, OWASP ASVS/Top 10/LLM and agentic-AI guidance, Sigma, YARA and Suricata. Record framework versions where available. A framework mapping is contextual metadata and never evidence by itself.

## Execution boundary

The selected agent adapter is the project orchestrator/operator/executor for a run. Skills, MCP servers, role configurations and framework mappings cannot grant privileges or bypass the VM/OS enforcement boundary. `policyctl` remains limited to host/security policy configuration and the local token-usage dashboard.

## Evidence

Claims must reference preserved evidence. Plans, prompts, skills, MCP responses, framework mappings and role conclusions are not substitutes for workload evidence. Important findings require independent verification.

## Completion

Do not start a subsequent experiment until `go-install-001` has passed or its failure has been documented and committed.
