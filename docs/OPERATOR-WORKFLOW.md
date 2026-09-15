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

cusimanse policy show
cusimanse policy validate
cusimanse policy explain <action>
cusimanse policy check <action>
cusimanse policy check-all
cusimanse policy require <action> [--approved]
cusimanse policy enforce <action> [--approved]
cusimanse policy audit

cusimanse install
cusimanse validate
cusimanse preflight
cusimanse test
cusimanse integration-test
cusimanse doctor
cusimanse observability status
cusimanse observability report <session-id>

cusimanse learning status <session-id>
cusimanse learning candidate <session-id> <candidate-id> <file>
cusimanse learning promote <session-id> <candidate-id> --approved
```

**Implementation note:** the policy and learning command forms above are the desired Go operator surface. The current repository's policy enforcement implementation is still `scripts/policyctl`, while learning operations are implemented by `scripts/learningctl`. Until native Go commands are wired to those helpers, use the helper commands shown below; do not invent a second policy or learning implementation.

The current operational commands use compatibility adapters for several shell helpers while deterministic logic is being migrated into Go. The API surface remains stable during that migration.

## Policy management

### Policy source of truth

The authoritative policy is:

- `policies/host-policy.yaml` — declarative authority decisions.
- `policies/mount-denylist.yaml` — host-mount restrictions referenced by experiments.
- `policies/permission-tiers.yaml` — permission-tier constraints referenced by experiments.
- `scripts/policyctl` — current compatibility enforcement helper.
- `cmd/cusimanse/` — Go capability boundary that invokes policy checks during lifecycle operations.
- `runs/policy-decisions.jsonl` — default append-only policy decision audit stream.

The current policy denies credentials, unrestricted mounts and untrusted host execution; requires approval for privileged/default actions, disposable VM creation, selected Git writes/pushes and learning helpers; allows Lima/QEMU and localhost services; denies public MCP and public gateway access; and requires evidence preservation and hashing.

### Policyctl commands

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

Available actions include:

| Action | Controls |
|---|---|
| `credentials` | host credential access |
| `mounts` | unrestricted host mounts |
| `host-root` | host filesystem access |
| `sudo` | privileged sudo |
| `vm` | disposable VM creation |
| `lima` | Lima virtualization |
| `qemu` | QEMU virtualization |
| `network` | localhost service access |
| `public-mcp` | public MCP access |
| `public-gateway` | public gateway access |
| `git-read` | repository read |
| `git-write` | repository write |
| `push` | Git push |
| `learning` | learning helpers |
| `host-execution` | untrusted host execution |
| `network-reconfig` | host network reconfiguration |

Use `explain` before `require` when the reason for a gate is unclear. Use `check` to record and display one decision. Use `check-all` for the baseline operator review. Use `require`/`enforce` at the capability boundary. Use `audit` after execution.

### Decision semantics

| Decision | Operator behavior | Exit code from `require`/`enforce` |
|---|---|---:|
| `allow`, `allowed`, `controlled` | Continue within the declared boundary. | 0 |
| `required` | Required control is satisfied; continue. | 0 |
| `approval-required` | Stop and obtain explicit researcher approval; then use `--approved`. | 3 without approval |
| `deny`, `denied` | Stop. Do not bypass, weaken or substitute an equivalent host action. | 4 |
| invalid/unknown | Stop and fix policy/action configuration. | 2 |

### Typical approval flow

```bash
scripts/policyctl validate
scripts/policyctl explain vm
scripts/policyctl check vm
scripts/policyctl require vm
# obtain explicit researcher approval outside the tool
scripts/policyctl require vm --approved
```

Never treat `--approved` as a mechanism for self-approval. The approval must already exist in the researcher's authorization decision and session audit.

## Profiles and requirements

The researcher declares requirements; the agent selects a registered profile. The agent does not create trusted profiles or add infrastructure fields to experiments.

### Capability registry

The source of truth is `recipes/profiles/registry.yaml`. It points to the host profile and four fixed workload profiles and requires deterministic resolution, fail-closed no-match/ambiguous-match behavior, agent selection without agent-created profiles.

Relevant files:

```text
recipes/profiles/registry.yaml
recipes/profiles/host/linux-lima.yaml
recipes/profiles/workload/go-install.yaml
recipes/profiles/workload/npm-install.yaml
recipes/profiles/workload/npm-lifecycle.yaml
recipes/profiles/workload/npm-threat.yaml
recipes/host/security-research.yaml
recipes/lima/security-research.yaml
recipes/instrumentation/security-research.yaml
```

### Requirements source

Experiment requirements live in `recipes/experiments/*.yaml`. For example, `npm-threat-001.yaml` declares disposable Linux execution, the `npm-threat` workload, localhost-only networking and process/syscall/filesystem/network instrumentation. It references its contract, policy files, session state, adapter/orchestration recipes, gateways, observability, Skills and MCP registry rather than duplicating infrastructure configuration.

Related researcher-facing files:

```text
contracts/<experiment>.md                      # intent, authorization, scope, acceptance
recipes/experiments/<experiment>.yaml          # requirements and references
recipes/profiles/registry.yaml                  # capability registry
recipes/profiles/host/*.yaml                    # reusable host capability
recipes/profiles/workload/*.yaml                # fixed workload capability
recipes/host/security-research.yaml             # host tool inventory
recipes/lima/security-research.yaml             # disposable compute definition
recipes/instrumentation/security-research.yaml # collectors/instrumentation
```

Resolution is performed by `cmd/cusimanse`:

```bash
cusimanse resolve npm-threat-001
```

The resolver must fail closed when no profile matches or when more than one profile matches. This keeps requirements declarative and prevents model-generated infrastructure from becoming trusted configuration.

## Learning loop — disabled by default

Learning is opt-in. The default is explicitly `false`; it requires a completed research report and independent verification, then a disposable replay and explicit human approval before promotion. The learning contract also forbids base-contract mutation, trusted-profile mutation, automatic privilege grants and automatic security-policy changes.

### Learning files

```text
recipes/session/learning-workflow.yaml  # learning contract and gates
recipes/session/session-state.yaml      # per-session learning.enabled state
scripts/learningctl                     # current learning operator helper
skills/candidate/                       # candidate skills
skills/validated/                       # approved reusable skills
runs/<session-id>/learning/              # candidate/evaluation/replay/verification/promotion artifacts
runs/<session-id>/evidence/              # source evidence
```

The session-state contract records learning as opt-in, with `learning.enabled=true` as the enable mechanism and `recipes/session/learning-workflow.yaml` as the recipe.

### Inspect and enable

First inspect the session:

```bash
./scripts/learningctl status <session-id>
```

Learning should only be enabled after the normal experiment and independent verification are complete. The contract's enablement step is:

```text
set runs/<session-id>/session.yaml learning.enabled=true
```

Then create a candidate:

```bash
./scripts/learningctl candidate <session-id> <candidate-id> <candidate-file>
```

Replay and independently verify the candidate in an authorized disposable environment. Only then promote:

```bash
./scripts/learningctl promote <session-id> <candidate-id> --approved
```

The workflow is:

```text
retrieve → propose → execute → evaluate → refine → replay
        → independent verification → human approval → promote
        → rollback if regression/safety impact is found
```

Learning never becomes a hidden privilege escalation path. A learned Skill is reusable behavior, not infrastructure authority.

## Evidence and report structure

Every research session is rooted at `runs/<session-id>/`. The session-state contract defines the durable artifacts and requires evidence/provenance hashing before destruction.

### Canonical structure

```text
runs/<session-id>/
├── session.yaml
├── evidence/
│   ├── index.yaml
│   ├── raw/                              # collected observations/artifacts
│   └── audit/
│       ├── events.jsonl                  # append-only lifecycle/policy audit
│       └── manifest.sha256               # evidence hash manifest
├── provenance/
│   └── manifest.sha256                   # provenance/input/tool hash manifest
├── analysis/
│   └── summary.md                        # specialist analysis synthesis
├── verification/
│   └── result.md                         # independent verification result
├── research-report/
│   ├── report.md                         # final human-readable report
│   └── report.yaml                        # structured report metadata/results
├── preservation/
│   └── manifest.yaml                     # preserved artifact inventory/status
├── observability/
│   ├── token-usage.yaml                   # token/cost-oriented telemetry
│   └── dashboard.yaml                     # final dashboard snapshot/status
└── learning/                              # only when learning is enabled/used
    ├── candidates/
    ├── evaluations/
    ├── replays/
    ├── verification/
    └── promotions/
```

### Evidence rules

1. Raw evidence is collected inside the disposable execution boundary.
2. Evidence is indexed and hashed before destruction.
3. Provenance records recipe/config/tool/agent inputs and versions.
4. Audit events record requested, approved, executed and observed decisions where applicable.
5. Model output is analysis, not raw evidence.
6. Independent verification challenges the evidence and conclusions.
7. The report is generated from requirements, preserved evidence, specialist analysis, verification and observability metadata.
8. Preservation completes before disposable compute is destroyed.
9. Missing mandatory telemetry or required evidence is a failure/partial result according to the session contract.

### Evidence and report commands

```bash
cusimanse observability report <session-id>
./scripts/session.sh create <experiment> <agent> <session-id>
./scripts/session.sh checkpoint <session-id> <STATE>
./scripts/session.sh hash <session-id>
./scripts/session.sh verify-layout <session-id>
```

The expected durable artifact names are defined by `recipes/session/session-state.yaml`; the integration test creates only test placeholders where necessary and verifies hashing/layout rather than claiming that placeholders are real research evidence.

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
