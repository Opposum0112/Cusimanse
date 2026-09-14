# Goose-native multiagent contract

The primary Goose session is the operator. It may delegate specialist work through the native Summon extension, reusable agent definitions and subrecipes. Goose documentation demonstrates planner, project-manager, architect, developer, QA and writer subagents and supports parallel subrecipe execution.

## Rules

- The primary session owns the research objective and final synthesis.
- Specialist agents receive explicit, bounded tasks.
- Independent verification must not be treated as proof merely because another agent produced it; verification must inspect the underlying evidence.
- Parallel subrecipes must avoid conflicting writes.
- No external orchestration framework is required.

## Native primitives

Use `.agents/agents/` for reusable agent definitions, `.agents/skills/` for reusable Skills, and recipe-local `sub_recipes` for bounded workflow tasks.
