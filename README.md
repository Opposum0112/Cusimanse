# Cusimanse — Goose-native security research

Cusimanse is a research workflow built directly around **goose** recipes, built-in extensions, Skills, Summon subagents/subrecipes, planning, headless execution, and optional Container Use isolation.

The design deliberately keeps the runtime small: Goose is the operator, Goose recipes are the executable workflow definition, and Goose-native capabilities do the orchestration. Capabilities that require a separate orchestration framework, alternate primary-agent runtime, custom gateway, custom policy controller, or custom observability runtime are not part of this branch's core.

## Native model

```text
Research contract
      ↓
Goose experiment recipe
      ↓
Goose primary session
      ├── Plan / Todo
      ├── Summon subagents / subrecipes
      ├── Skills
      └── Developer + selected MCP extensions
      ↓
Optional Container Use isolated environment
      ↓
Workload / analysis
      ↓
Evidence files + research report
      ↓
Goose session history / ClawMetry (optional)
```

Goose recipes package instructions, parameters, extensions and subrecipes into reusable workflows. Subrecipes execute in isolated sessions and can run in parallel when the prompt explicitly requests it. Goose's Skills platform extension discovers project skills from `.agents/skills/`. urlGoose recipe documentationhttps://goose-docs.ai/docs/guides/recipes/

## Quick start

Install and configure Goose using the official Goose installation flow. Then from this repository:

```bash
goose recipe validate recipes/goose-research/recipe.yaml
goose run --recipe recipes/goose-research/recipe.yaml --interactive
```

For a reference experiment:

```bash
goose recipe validate recipes/go-install-001/recipe.yaml
goose run --recipe recipes/go-install-001/recipe.yaml --interactive
```

Headless automation is also supported because the recipes contain a `prompt` field:

```bash
goose run --recipe recipes/go-install-001/recipe.yaml
```

Goose's documented CLI supports recipe validation, parameterized execution, headless `run`, interactive recipe execution, and structured JSON output. urlGoose CLI commandshttps://goose-docs.ai/docs/guides/goose-cli-commands/

## Researcher workflow

1. Define the question and authorization in a Markdown contract.
2. Choose or create a Goose experiment recipe.
3. Validate the recipe with `goose recipe validate`.
4. Start the recipe interactively for research that needs human decisions, or use headless mode for deterministic automation.
5. Let Goose use Plan/Todo, Skills and Summon subagents/subrecipes as declared by the recipe.
6. Use Container Use when an isolated container environment is appropriate.
7. Execute the workload and record observed evidence as files; model output is analysis, not evidence.
8. Ask specialist subrecipes to analyze independent evidence where useful.
9. Run the verification subrecipe after analysis.
10. Produce the research report and preserve the evidence in the experiment directory.

Goose's official tutorials document recipes, built-in extensions, Skills, subagents, parallel subrecipes, headless execution and isolated Container Use workflows. urlGoose tutorialshttps://goose-docs.ai/docs/category/tutorials/

## What is intentionally not in this branch

The Goose-native refactor does **not** make these separate runtime layers part of the execution model:

- CrewAI, LangGraph or Taskflow as orchestration controllers
- alternate primary-agent adapters for OpenCode/Grok/Antigravity/Pi/Hermes/Codex/etc.
- LiteLLM/OmniRoute or another custom model gateway
- a custom `policyctl` control plane
- custom Numbat/Phoenix/Aegis orchestration
- a custom session-state engine or blackboard service
- Lima/QEMU as a Goose-native requirement

These can be studied independently, but they are not represented as required Goose capabilities. For isolation, the native Goose-supported Container Use integration is the reference option; it uses Docker and provides isolated development environments. urlGoose Container Use extensionhttps://goose-docs.ai/docs/mcp/container-use-mcp/

## Project structure

```text
.goosehints
.agents/skills/                 # Goose-compatible project skills
contracts/                      # research contracts and acceptance rules
recipes/
├── goose-research/             # main reusable Goose workflow
├── go-install-001/             # Go reference experiment
├── npm-install-001/            # npm reference experiment
└── subrecipes/                 # native Goose specialist workflows
docs/
└── architecture/               # canonical Goose-native architecture
packages/labprobe/              # small reference workload fixture
```

## Observability

Goose already persists session information locally. The Goose ecosystem provides ClawMetry as a read-only local dashboard over the Goose session store, so token and session visibility does not require a custom telemetry control plane. urlClawMetry tutorialhttps://goose-docs.ai/docs/tutorials/clawmetry/

## Safety boundary

This branch is a **Goose workflow project, not a security sandbox**. Goose's Developer extension can execute shell commands with the user's privileges, so researchers must choose an appropriately isolated working environment and configure Goose permissions deliberately. The official documentation explicitly describes the Developer extension as capable of shell execution and file editing. urlGoose Developer extensionhttps://goose-docs.ai/docs/mcp/developer-mcp/

Container Use is the preferred Goose-supported isolation integration for experiments requiring an isolated development environment; it does not turn Goose itself into a security boundary. 

## License

MIT. See `LICENSE`.
