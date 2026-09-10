# 09 — Operations and Maintenance

## Daily

- inspect Git status
- inspect failed agent tasks
- inspect policy events
- inspect VM inventory
- inspect disk usage
- inspect observability health

## Before upgrades

Create a Git checkpoint.

Record current versions.

Update one layer at a time:

1. host packages
2. Lima/QEMU
3. harnesses
4. gateway
5. MCP
6. Aegis/Numbat
7. observability
8. experiment tooling

Validate after each layer.

## Rollback

Keep:
- configuration in Git
- pinned versions
- reproducibility manifests
- known-good commits

Rollback the smallest possible component.

## Backups

Back up:
- Git repository
- experiment manifests
- evidence indexes
- reports
- skills
- agent definitions
- policy definitions
- gateway configuration without secrets

Never back up secrets into the repository.

## Troubleshooting order

1. host resources
2. QEMU
3. Lima
4. VM network
5. instrumentation
6. MCP
7. Aegis
8. Numbat
9. harness
10. model gateway
11. Phoenix/OTel

## Resource pressure

On 16 GB RAM:
- stop unused VMs
- stop unused observability services
- avoid concurrent heavyweight agents
- reduce capture scope
- archive large PCAPs
- prefer hosted models

## Update principle

Do not update the entire stack simultaneously.

A reproducible security lab is more valuable than a constantly changing stack.
