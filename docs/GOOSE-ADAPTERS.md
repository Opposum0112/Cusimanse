# Goose Summon and Agent Adapters

## Summon extension

Goose's `summon` platform extension provides the `load` and `delegate` tools used to load knowledge and delegate work to subagents. When a recipe has an explicit `extensions:` block, the recipe should explicitly declare `summon` if it needs those tools. Cusimanse therefore declares it explicitly in `recipes/npm-threat-001/recipe.yaml` rather than relying on implicit availability.

Cusimanse treats Summon as **agent orchestration, not infrastructure authority**. A delegated specialist can analyze preserved evidence, verify conclusions or generate a report, but it cannot authorize a VM, widen network scope, change policy, create a trusted profile or execute the research workload on the host.

Goose's recipe/subrecipe model is:

```text
Goose recipe
  ├── instructions / prompt
  ├── explicit extensions (including summon when needed)
  └── sub_recipes
        ├── evidence analysis
        ├── independent verification
        └── report generation
```

For the reference experiment:

```bash
goose recipe validate recipes/npm-threat-001/recipe.yaml
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The recipe delegates analysis/verification/reporting, while the actual lifecycle remains:

```text
resolve → policy → provision → instrument → execute → collect
→ evidence/hash → specialist analysis → independent verification
→ report → preserve → destroy
```

## Adapter matrix

The canonical adapter contract is `recipes/agents/adapter-matrix.yaml`.

| Agent | Invocation | Role | Boundary |
|---|---|---|---|
| Goose | `goose run --recipe <recipe> --interactive` | Native reference operator | Recipe + Summon + Cusimanse |
| OpenCode | `opencode <prompt-reference-or-project-session>` | Prompt handoff adapter | Cusimanse capability boundary |
| Hermes | `hermes <prompt-reference-or-project-session>` | Prompt handoff adapter | Cusimanse capability boundary |
| Antigravity | `agy <prompt-reference-or-project-session>` | Prompt handoff adapter | Cusimanse capability boundary |
| Pi | `pi <prompt-reference-or-project-session>` | Prompt handoff adapter | Cusimanse capability boundary |

The non-Goose commands are intentionally adapter placeholders because each agent's installed CLI can differ. The stable input is the contract, experiment requirements and prompt reference—not an adapter-specific infrastructure recipe.

## Adapter rules

Every adapter must:

1. read the contract and requirements;
2. preserve authorization and experiment scope;
3. use the declared prompt/reference and recipe rather than inventing infrastructure;
4. invoke Cusimanse for capability execution;
5. respect policy decisions and explicit approval gates;
6. record unsupported capabilities as partial rather than improvising;
7. preserve evidence, independent verification and report artifacts.

An adapter must **not**:

- mutate a trusted profile or experiment infrastructure;
- widen policy/network/credential authority;
- execute the untrusted workload directly on the host;
- treat an LLM response as evidence;
- bypass `policyctl`/Go capability controls.

## Files involved

```text
recipes/agents/adapter-matrix.yaml       # adapter contract and operator sequence
recipes/agents/goose-orchestration.yaml  # Goose orchestration
recipes/npm-threat-001/recipe.yaml       # reference Goose recipe + summon
recipes/subrecipes/evidence-analysis.yaml
recipes/subrecipes/verification.yaml
recipes/subrecipes/report.yaml
prompts/experiments/                     # agent-neutral handoff prompts
contracts/npm-threat-001.md              # experiment authorization and acceptance
recipes/experiments/npm-threat-001.yaml  # declarative requirements
cmd/cusimanse/                            # capability boundary
policies/                                 # authority rules
```

## Validation

Recipe syntax and the explicit Summon declaration are validated separately from runtime capability tests:

```bash
goose recipe validate recipes/npm-threat-001/recipe.yaml
cusimanse validate
cusimanse test
cusimanse integration-test
```

A CLI being installed is not enough to mark an adapter deployed. `recipes/agents/adapter-matrix.yaml` requires runtime evidence and independent verification before an adapter leaves `NOT_DEPLOYED` status.
