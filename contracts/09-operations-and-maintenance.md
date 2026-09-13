# 09 — Operations and Maintenance

![Architecture](../docs/images/cusimanse-architecture.svg)

## Daily checks

```bash
git status
./policyctl check
```

Review audit events, failed agent tasks, compute inventory, disk usage and observability health.

## Upgrades

Checkpoint Git first. Upgrade one layer at a time:

1. host packages
2. QEMU/Lima
3. primary agent adapter
4. MCP servers
5. skills
6. security tooling
7. model routing
8. observability

Re-run the project preflight after each layer.

## Recovery

Troubleshoot in this order: host resources → QEMU → Lima → compute networking → instrumentation → MCP → audit/policy → agent adapter → model routing → observability.

## Token dashboard

```bash
./policyctl token-dashboard
```

Keep it localhost-only unless explicitly changed by a controlled deployment recipe.
