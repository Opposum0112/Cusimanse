# Skills Registry

Skills are versioned reusable procedures.

## Structure

```text
skills/
├── lima-disposable-vm/
│   ├── SKILL.md
│   ├── README.md
│   └── tests/
├── evidence-reduction/
│   ├── SKILL.md
│   └── tests/
├── network-forensics/
├── syscall-analysis/
├── agent-security-review/
├── git-archival/
└── experiment-reporting/
```

## Skill requirements

Every skill should define:
- purpose
- inputs
- outputs
- permissions
- commands
- safety constraints
- examples
- tests
- version

## Antigravity integration

Project-specific Antigravity skills should live under:

```text
.agents/skills/
```

Global Antigravity skills may be installed under its documented global skills directory.

Do not let a skill grant broader authority than its MCP/policy tier.

## Versioning

Use semantic versions where practical.

Record the skill version in experiment manifests.
