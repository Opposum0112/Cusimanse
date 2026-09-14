# Prompt references

This directory contains **handoff prompts**, not a second experiment configuration.

The YAML experiment recipe remains the source of truth for workload, VM,
instrumentation, evidence, verification and reporting. A prompt tells a primary
agent how to consume that recipe and complete the lifecycle.

## Reference experiments

- `go-install-001.md` — Go installation experiment.
- `npm-install-001.md` — npm installation experiment.

## Goose

Goose can use the experiment recipe natively. The researcher starts Goose and
selects the recipe; Goose can delegate specialist roles using its native agent,
subagent, Skill and MCP/extension mechanisms.

## Other primary agents

A researcher may use OpenCode, Hermes, Antigravity or Pi when its adapter is
installed and its runtime integration has been validated.

The flow is:

```text
Contract + experiment recipe + prompt reference
                    ↓
          selected primary agent
                    ↓
       native tools / delegation
                    ↓
       same Lima VM + workload
                    ↓
          same evidence/report
```

The prompt does **not** copy the workload into a competing configuration. It
points the agent at the contract and recipe. If an agent cannot natively
perform a requested capability, the adapter must record the capability as
unsupported rather than silently changing the experiment.

## Running a prompt

Example pattern:

```bash
# Goose: use the recipe natively
# Other agents: start the installed agent, then provide the matching prompt.
cat prompts/experiments/go-install-001.md
```

The prompt should be supplied to the selected agent in its normal interactive
interface. The adapter matrix documents the agent-specific handoff command.

## Adding an experiment prompt

Create one prompt per reference experiment. Keep it short and stable:

1. identify the contract;
2. identify the experiment recipe;
3. require the full lifecycle;
4. state that workload commands run inside disposable compute;
5. require evidence, independent verification and report output;
6. point to the session-state and learning workflow when applicable.

Do not duplicate recipe fields in the prompt.
