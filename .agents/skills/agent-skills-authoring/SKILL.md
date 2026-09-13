---
name: agent-skills-authoring
description: Author and review portable Agent Skills using the Agent Skills open format, precise trigger descriptions, progressive disclosure, and explicit security metadata.
---

# Agent Skills authoring

## Use when
- creating a new Cusimanse skill
- importing or adapting an external SKILL.md
- reviewing whether a skill is complete and safely scoped

## Required structure
1. Use `SKILL.md` as the skill entrypoint.
2. Keep frontmatter minimal: a stable name and actionable description.
3. Put essential instructions in the entrypoint; move large references/examples into adjacent files.
4. Describe when the skill should and should not trigger.
5. Document tools, network access, filesystem assumptions, secrets, and destructive actions.
6. Treat skills as instructions, never as a security boundary.

## Security review
- Inspect every referenced script and resource.
- Reject hidden installers, credential collection, arbitrary host execution, or unexplained network calls.
- Record provenance and source revision for imported skills.
- Require explicit approval before copying external skills into the deployment set.
- Unknown or unavailable capability is `NOT_DEPLOYED`.

## Cusimanse integration
A skill may select tools, MCP servers, roles, or analysis stages, but it cannot grant privileges. VM/OS controls, mount policy, network policy, approval gates, and evidence preservation remain authoritative.
