# 11 — Harness Reference

![Architecture](docs/images/ai-security-lab-architecture.svg)

## Role of external harnesses

Antigravity, OpenCode, Codex and other harnesses may be useful development or research clients, but they are not the project execution authority in this architecture. Goose owns the project recipe workflow.

## MCP and skills

The repository keeps capability definitions portable through:

- `recipes/mcp/registry.yaml`
- `recipes/skills/registry.yaml`
- `.agents/skills/`

The registry is the project inventory; actual client configuration remains harness-specific.

## Volatile external behavior

Do not hard-code undocumented model names, pricing, provider behavior or client-specific configuration into the core security contract. Verify current external-harness documentation before deployment.
