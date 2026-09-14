# Cusimanse operator workflow

This is the operational companion to the researcher workflow in `README.md`. It defines the command sequence for Goose and prompt-handoff adapters without making an agent an infrastructure authority.

## Authority model

- The researcher owns intent, authorization, scope and approval.
- Goose is the native reference operator and orchestrates recipes, subrecipes, delegation and Skills.
- Other agents are adapters. They receive the same contract, experiment requirements and prompt handoff.
- `cusimanse` is the capability boundary for resolve/provision/configure/execute/collect/destroy and operational controls.
- `scripts/policyctl` reads the declarative policy and records decisions; it is an enforcement compatibility helper, not a competing policy authority.
- Lima/QEMU is the execution boundary. Adapters must not execute an untrusted research workload directly on the host.

## Normal operator sequence

From the repository root:

```bash
cusimanse doctor
cusimanse validate
cusimanse preflight

goose recipe validate recipes/npm-threat-001/recipe.yaml
cusimanse resolve npm-threat-001

scripts/policyctl explain vm
scripts/policyctl explain network
scripts/policyctl check-all
scripts/policyctl require vm
```

Stop for researcher approval when a decision is `approval-required`. Then:

```bash
scripts/policyctl require vm --approved
cusimanse --approved run npm-threat-001 <session-id>
```

After execution:

```bash
cusimanse observability report <session-id>
scripts/policyctl audit
```

The run must preserve evidence and provenance before destroying disposable compute. Verification and report generation consume preserved artifacts rather than trusting model output as evidence.

## Goose commands

### Start an interactive recipe

```bash
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

### Validate a recipe before operation

```bash
goose recipe validate ./recipes/npm-threat-001/recipe.yaml
```

### Validate all repository recipes

```bash
for recipe in recipes/*/recipe.yaml; do goose recipe validate "$recipe"; done
for recipe in recipes/subrecipes/*.yaml; do goose recipe validate "$recipe"; done
```

Goose-native features such as subrecipes, Skills, delegation and MCP/extensions remain agent orchestration features. They do not bypass Cusimanse policy or the execution boundary.

## Cusimanse commands exposed to the operator

```text
cusimanse resolve <experiment>
cusimanse provision <experiment> <session-id>
cusimanse configure <experiment> <session-id>
cusimanse execute <experiment> <session-id>
cusimanse collect <experiment> <session-id>
cusimanse destroy <experiment> <session-id>
cusimanse --approved run <experiment> [session-id]

cusimanse capability list
cusimanse capability skill list
cusimanse capability skill upsert ...
cusimanse capability role list
cusimanse capability role upsert ...

cusimanse install
cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
cusimanse doctor
cusimanse observability status
cusimanse observability report <session-id>
```

The current operational commands use compatibility adapters for several shell helpers while deterministic logic is being migrated into Go. The API surface remains stable during that migration.

## Policyctl commands

```bash
scripts/policyctl show
scripts/policyctl validate
scripts/policyctl explain vm
scripts/policyctl explain network
scripts/policyctl check vm
scripts/policyctl check-all
scripts/policyctl require vm
scripts/policyctl require vm --approved
scripts/policyctl enforce vm --approved
scripts/policyctl audit
```

### Decision semantics

| Decision | Operator behavior |
|---|---|
| `allow` / `allowed` / `controlled` | Continue within the declared boundary. |
| `approval-required` | Stop and obtain explicit researcher approval. Use `--approved` only after that approval exists. |
| `deny` / `denied` | Stop. Do not bypass, weaken or substitute a host action. |
| `required` | Required control is satisfied; continue. |

Exit codes for `require`/`enforce`: `0` allowed, `3` approval required but not approved, `4` denied, `2` invalid policy/action.

## Adapter handoff

The adapter matrix is `recipes/agents/adapter-matrix.yaml` and prompt references are under `prompts/experiments/`.

Supported handoff commands are intentionally represented as command placeholders because installed CLI syntax varies by adapter:

```text
opencode <prompt-reference-or-project-session>
hermes <prompt-reference-or-project-session>
agy <prompt-reference-or-project-session>
pi <prompt-reference-or-project-session>
```

An adapter is considered deployed only after runtime evidence and independent verification. CLI presence alone is insufficient. An adapter must:

1. read the contract and requirements;
2. preserve experiment scope;
3. invoke Goose/Cusimanse according to the declared operator sequence;
4. record unsupported capabilities as partial rather than silently improvising;
5. preserve evidence, verification and report artifacts.

## Integration test

The repository integration test is the cross-layer gate:

```bash
cusimanse integration-test
```

It checks inventory, gateways, observability, policy decisions, adapter contracts, prompts, Goose recipes, roles/Skills, learning controls, capability resolution, session creation/checkpoints and evidence hashing. Set `CUSIMANSE_RUN_VM_TEST=1` to additionally validate and run the disposable Lima recipe and verify guest instrumentation before destruction.
