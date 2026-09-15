# Goose Summon and Agent Adapters

## Prompt library and handoff model

Cusimanse has one **agent-neutral experiment prompt library** under `prompts/experiments/`. The prompt is the handoff artifact shared by Goose and every alternate operator. It carries the research workflow and references the contract, experiment requirements, recipe, session state and adapter matrix; it does **not** grant authority.

Each alternate operator also has a thin operator-specific handoff guide under `prompts/operators/`. These guides translate the shared experiment handoff into that operator's native planning/tool/delegation model without duplicating infrastructure instructions.

```text
researcher intent
      ↓
contracts/<experiment>.md
      +
recipes/experiments/<experiment>.yaml
      ↓
prompts/experiments/<experiment>.md   ← shared handoff
      ↓
┌──────────┬──────────┬──────────┬─────────────┐
│ Goose    │ OpenCode │ Hermes   │ Antigravity │ … Pi
│ native   │ adapter  │ adapter  │ adapter     │
└────┬─────┴────┬─────┴────┬─────┴──────┬──────┘
     │          │           │             │
     └──────────┴───────────┴─────────────┘
                         ↓
              Cusimanse Go capability API
                         ↓
                 policy + execution plan
                         ↓
                  disposable compute
```

**If any operator other than Goose is used, the operator must use the shared experiment prompt plus its operator guide. It must not invent a parallel recipe or infrastructure workflow.**

### Prompt files

```text
prompts/experiments/<experiment>.md     # shared, agent-neutral research handoff
prompts/operators/goose.md              # optional/native Goose guidance when present
prompts/operators/opencode.md            # OpenCode handoff
prompts/operators/hermes.md              # Hermes handoff
prompts/operators/antigravity.md         # Antigravity handoff
prompts/operators/pi.md                  # Pi handoff
```

An experiment prompt should explicitly identify all files the operator needs to read. The npm threat reference does this in `prompts/experiments/npm-threat-001.md`.

## Summon extension

Goose's `summon` platform extension provides `load` and `delegate` for specialist subagents. When a recipe has an explicit `extensions:` block, it explicitly declares `summon` when those tools are required. Cusimanse therefore declares it in `recipes/npm-threat-001/recipe.yaml`.

Summon is **agent orchestration, not infrastructure authority**. A delegated specialist can analyze preserved evidence, verify conclusions or generate a report, but cannot authorize a VM, widen network scope, change policy, create a trusted profile or execute the research workload on the host.

```text
Goose recipe
  ├── instructions / shared prompt
  ├── explicit extensions (summon when needed)
  └── sub_recipes
        ├── evidence analysis
        ├── independent verification
        └── report generation
```

## Adapter matrix

The canonical adapter contract is `recipes/agents/adapter-matrix.yaml`.

| Agent | Invocation | Role | Handoff |
|---|---|---|---|
| Goose | `goose run --recipe <recipe> --interactive` | Native reference operator | Recipe + shared prompt + Summon + Cusimanse |
| OpenCode | `opencode <prompt-reference-or-project-session>` | Prompt handoff adapter | Shared experiment prompt + OpenCode guide + Cusimanse |
| Hermes | `hermes <prompt-reference-or-project-session>` | Prompt handoff adapter | Shared experiment prompt + Hermes guide + Cusimanse |
| Antigravity | `agy <prompt-reference-or-project-session>` | Prompt handoff adapter | Shared experiment prompt + Antigravity guide + Cusimanse |
| Pi | `pi <prompt-reference-or-project-session>` | Prompt handoff adapter | Shared experiment prompt + Pi guide + Cusimanse |

The non-Goose commands are adapter placeholders because installed CLI syntax can differ. The stable inputs are the contract, experiment requirements and prompt reference—not an adapter-specific infrastructure recipe.

## Adapter rules

Every adapter must:

1. read the contract and requirements;
2. read the shared experiment prompt;
3. read its operator-specific handoff guide when one exists;
4. preserve authorization and experiment scope;
5. use the declared recipe/reference rather than inventing infrastructure;
6. invoke Cusimanse for capability execution;
7. respect policy decisions and explicit approval gates;
8. record unsupported capabilities as `PARTIAL` rather than improvising;
9. preserve evidence, independent verification and report artifacts.

An adapter must **not**:

- mutate a trusted profile or experiment infrastructure;
- widen policy/network/credential authority;
- execute the untrusted workload directly on the host;
- treat an LLM response as evidence;
- bypass Go policy/capability controls.

## Files involved

```text
recipes/agents/adapter-matrix.yaml       # adapter contract, prompt refs and operator sequence
recipes/agents/goose-orchestration.yaml  # Goose orchestration
recipes/npm-threat-001/recipe.yaml       # reference Goose recipe + summon
recipes/subrecipes/evidence-analysis.yaml
recipes/subrecipes/verification.yaml
recipes/subrecipes/report.yaml
prompts/experiments/                     # shared experiment handoff library
prompts/operators/                       # operator-specific handoff guides
contracts/npm-threat-001.md              # authorization and acceptance
recipes/experiments/npm-threat-001.yaml  # declarative requirements
recipes/session/session-state.yaml       # durable session/adapter identity
cmd/cusimanse/                            # capability boundary
policies/                                 # authority rules
```

## Validation

```bash
goose recipe validate recipes/npm-threat-001/recipe.yaml
cusimanse validate
cusimanse test
cusimanse integration-test
```

Validation must check that every supported alternate adapter has its operator guide and that every reference experiment has its shared prompt. CLI presence alone never marks an adapter deployed; runtime evidence and independent verification are required.