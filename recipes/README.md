# Recipe-Only Project Model

The AI Security Lab is configured through YAML recipes. Goose is the agentic orchestrator, operator, and execution layer. A small separate policy CLI is reserved for host/security policy configuration.

## Boundary

```text
Markdown contracts
      ↓
YAML recipe (project configuration)
      ↓
Goose — plan / review / operate / execute / investigate / verify / report
      ↓
Policy CLI — explicit host policy configuration
      ↓
Lima / QEMU / instrumentation / evidence
```

Recipes describe what the project should do; Goose decides and executes the workflow. The policy CLI configures safety constraints and is not a second orchestration plane.

## Design rule

**One recipe for configuration. One agentic operator. One separate policy CLI.**

Keep deterministic helpers small and capability-specific. Do not recreate the project orchestration lifecycle in a second Go controller.
