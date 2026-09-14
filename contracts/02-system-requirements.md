# Goose-native experiment contract

## Research model
Cusimanse uses a Markdown contract for the research question, authorization, scope, safety expectations, evidence requirements and acceptance criteria. The executable configuration is a Goose recipe.

## Native execution

```text
Contract → Goose recipe → Goose session → Plan → Summon/Skills/MCP → workload → evidence → verification → report
```

Use `goose recipe validate <recipe.yaml>` before execution. Recipes must use Goose's supported YAML schema and must not depend on a second orchestration framework.

## Evidence
Record command output, files, hashes and other observable artifacts in the experiment directory. AI responses are analysis and are not evidence by themselves.

## Acceptance
A successful research run requires the requested workload to execute in the selected environment, evidence to be preserved, and important conclusions to be independently checked. If an optional capability is unavailable, report it as unavailable rather than simulating it.
