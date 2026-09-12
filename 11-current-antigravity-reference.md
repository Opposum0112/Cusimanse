# 11 — Harness Reference

![Architecture](docs/images/ai-security-lab-architecture.svg)

## Role of external harnesses

Antigravity, OpenCode, Codex and other harnesses may be useful development or research clients. **Goose is the primary Cusimanse operator, executor and lifecycle orchestrator.** Compatible adapters consume the same Markdown contracts and YAML recipes.

CrewAI is an optional role-based multi-agent orchestration framework. It can coordinate specialist research roles inside a declared Cusimanse run, but it is not a project controller and cannot bypass Goose, `policyctl`, approval, audit or VM/cloud enforcement.

## MCP and skills

The repository keeps capability definitions portable through:

- `recipes/mcp/registry.yaml`
- `recipes/skills/registry.yaml`
- `.agents/skills/`

The registry is the project inventory; actual client configuration remains harness-specific. CrewAI roles must use the same approved tool, MCP and skill registries.

## Volatile external behavior

Do not hard-code undocumented model names, pricing, provider behavior or client-specific configuration into the core security contract. Verify current external-harness documentation before deployment.
