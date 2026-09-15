# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-operated security research on disposable compute.** Researchers declare intent and requirements; agents plan, select and analyze; the Go capability API and policy decide whether and how execution may occur.

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

> Contract → requirements → prompt handoff → agent → capability resolution → Go runtime → policy/approval → Lima/QEMU → instrumentation/workload → evidence → analysis → independent verification → report → preservation → destroy.

## Table of contents

- [What Cusimanse is](#what-cusimanse-is)
- [Architecture and authority boundary](#architecture-and-authority-boundary)
- [Researcher workflow](#researcher-workflow)
- [Prompt library and agent handoff](#prompt-library-and-agent-handoff)
- [Host tooling and installation](#host-tooling-and-installation)
- [Gateways](#gateways)
- [Observability](#observability)
- [Lima/QEMU and guest tooling](#limaqemu-and-guest-tooling)
- [Go capability API and commands](#go-capability-api-and-commands)
- [Roles, Skills and learning loop](#roles-skills-and-learning-loop)
- [Profiles and requirements](#profiles-and-requirements)
- [Policy and safety](#policy-and-safety)
- [Evidence and reproducibility](#evidence-and-reproducibility)
- [Reference experiments](#reference-experiments)
- [Validation and integration testing](#validation-and-integration-testing)
- [Repository map](#repository-map)

## What Cusimanse is

| Layer | Responsibility | Source of truth |
|---|---|---|
| Contract | purpose, authorization, scope, acceptance | `contracts/` |
| Requirements | OS, isolation, workload, network, instrumentation | `recipes/experiments/` |
| Prompt library | agent-neutral handoff | `prompts/experiments/` |
| Operator guides | thin adapter handoff | `prompts/operators/` |
| Profiles | trusted reusable capabilities | `recipes/profiles/` |
| Runtime | resolution, policy, lifecycle, execution boundary | `cmd/cusimanse/`, `internal/` |
| Policy | authority and approval | `policies/`, `internal/policy/` |
| Containment | disposable compute | `recipes/lima/`, Lima/QEMU |
| Evidence | observations, provenance, verification | `runs/<session-id>/` |

The agent cannot create trusted profiles, expand policy, mutate trusted recipes or execute an untrusted workload directly on the host.

## Architecture and authority boundary

1. **Declaration:** contract + YAML requirements.
2. **Handoff:** shared experiment prompt plus optional operator guide.
3. **Planning:** Goose is the native reference operator; other agents use adapters.
4. **Resolution:** Go resolves requirements against registered profiles and fails closed on ambiguity.
5. **Policy:** Go evaluates authority and approval gates and audits decisions.
6. **Execution:** capabilities operate Lima/QEMU and fixed workload handlers.
7. **Evidence:** collect, hash, independently verify, report, preserve, then destroy disposable compute.

> **Boundary rule:** the agent decides what research to do; Cusimanse decides whether and how it may execute.

## Researcher workflow

### 1. Contract and requirements

Write `contracts/<experiment>.md` with research question, authorization, scope, acceptance criteria and safety constraints. Declare only requirements in `recipes/experiments/<experiment>.yaml`.

Example:

```yaml
requirements:
  execution: disposable
  os: linux
  workload: npm-threat
  network: localhost-only
  instrumentation: [process, syscall, filesystem, network]
```

### 2. Bootstrap and deterministic validation

```bash
./scripts/install.sh
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
cusimanse doctor
cusimanse validate
cusimanse preflight
cusimanse policy validate
cusimanse test
cusimanse integration-test
```

### 3. Validate and run the Goose recipe

```bash
goose recipe validate recipes/npm-threat-001/recipe.yaml
goose recipe validate recipes/subrecipes/evidence-analysis.yaml
goose recipe validate recipes/subrecipes/verification.yaml
goose recipe validate recipes/subrecipes/report.yaml
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The recipe explicitly declares the `summon` platform extension. Summon provides delegation/orchestration only; it does not authorize execution.

### 4. Resolve and approve

```bash
cusimanse resolve npm-threat-001
cusimanse policy explain vm
cusimanse policy explain network
cusimanse policy check-all
cusimanse policy require vm --approved
```

### 5. Execute and finish

```bash
cusimanse --approved run npm-threat-001 <session-id>
cusimanse observability report <session-id>
cusimanse policy audit
```

Lifecycle: `resolve → policy → provision → configure → instrument → execute → collect → verify → report → preserve → destroy`.

## Prompt library and agent handoff

The prompt is a **handoff**, not an authority layer and not a second recipe.

```text
prompts/experiments/<experiment>.md       shared research handoff
prompts/operators/<operator>.md           thin operator guidance
recipes/experiments/<experiment>.yaml     requirements source of truth
recipes/<experiment>/recipe.yaml          Goose/runtime recipe
contracts/<experiment>.md                 authorization/scope source
```

For OpenCode, Hermes, Antigravity or Pi, provide the same contract, experiment YAML, recipe references, shared prompt and matching operator guide. The alternate operator may plan/delegate/analyze using its native features, but must invoke Cusimanse for capability execution. Unsupported capabilities are recorded as `PARTIAL`; adapters cannot mutate policy, profiles or trusted recipes.

Canonical adapter configuration: `recipes/agents/adapter-matrix.yaml` and `docs/GOOSE-ADAPTERS.md`.

## Host tooling and installation

Authoritative inventory: `recipes/host/security-research.yaml`. Detailed access/configuration guide: `docs/HOST-TOOLCHAIN.md`.

```bash
./scripts/install.sh
cusimanse tools list
cusimanse tools versions
cusimanse tools config
cusimanse tools path
```

Host tools include Git, Bash, curl, Python, Node/npm, Go, jq, yq, ripgrep and Goose. Platform tools include Lima/QEMU. Guest instrumentation includes `strace`, `tcpdump`, `ss`, `ip`, `dig`, `getent`, `lsof`, `find`, `stat`, `sha256sum`, `inotifywait`, `file`, `ps` and `pgrep`.

Key repository configuration:

```text
recipes/host/security-research.yaml
recipes/gateway/mandatory.yaml
recipes/observability/mandatory.yaml
recipes/lima/security-research.yaml
recipes/instrumentation/security-research.yaml
policies/host-policy.yaml
```

Installer-generated user configuration:

```text
~/.config/cusimanse/litellm.yaml
~/.config/cusimanse/omniroute.env
~/.config/cusimanse/observability.env
~/.config/cusimanse/goose.env
~/.local/share/cusimanse/aegis/
~/.local/share/cusimanse/venv/
~/.numbat/cusimanse.ndjson
```

## Gateways

`recipes/gateway/mandatory.yaml` defines localhost-only model routing:

```text
agent/Goose → LiteLLM :4000 → OmniRoute :20128 → provider
```

Gateway configuration is generated by the installer and secrets are environment-only. Gateways are not security boundaries; policy remains authoritative.

## Observability

> **Goose observes the agent; Cusimanse observes the experiment.**

Declared by `recipes/observability/mandatory.yaml`:

| Observer | Access | Data/UI |
|---|---|---|
| Numbat | `cusimanse tools numbat` | `~/.numbat/cusimanse.ndjson` |
| Phoenix | browser | `http://127.0.0.1:6006` |
| OpenTelemetry | OTLP/HTTP | `http://127.0.0.1:4318` |
| ClawMetry | browser | `http://127.0.0.1:8900` |
| Aegis | `cusimanse observability status` | `~/.local/share/cusimanse/aegis/` |

```bash
cusimanse observability status
cusimanse observability phoenix
cusimanse observability clawmetry
cusimanse observability report <session-id>
```

Per-run snapshots are under `runs/<session-id>/observability/` with required experiment/session/run/agent/role/skill/capability/workload/trace correlation.

## Lima/QEMU and guest tooling

Source of truth: `recipes/lima/security-research.yaml`.

```bash
limactl validate recipes/lima/security-research.yaml
limactl start --name=cusimanse-smoke recipes/lima/security-research.yaml
limactl shell cusimanse-smoke -- bash -lc 'go version && node --version && npm --version && strace -V'
limactl delete --force cusimanse-smoke
```

The VM is disposable. Do not add credentials, unrestricted mounts or external destinations. Guest collectors run inside the Linux boundary.

## Go capability API and commands

Native control-plane commands:

```bash
cusimanse resolve <experiment>
cusimanse validate
cusimanse preflight
cusimanse policy validate
cusimanse policy explain <action>
cusimanse policy check <action>
cusimanse policy check-all
cusimanse policy require <action> [--approved]
cusimanse capability list
cusimanse capability role list
cusimanse capability skill list
cusimanse session create <experiment> <agent> <session-id>
cusimanse observability report <session-id>
cusimanse learning status <session-id>
cusimanse test
cusimanse integration-test
cusimanse doctor
```

Native Go validation, preflight and policy are authoritative. Shell remains for OS/package-manager bootstrap, compatibility and unavoidable external tools.

## Roles, Skills and learning loop

Sources: `recipes/agents/role-skill-registry.json`, `recipes/agents/role-skill-bindings.yaml`, generated `.agents/agents/`, and `recipes/skills/`.

Learning is **disabled by default** and approval-gated:

```text
research run → preserved evidence/analysis → candidate Skill
→ replay → independent verification → researcher approval
→ skills/validated/<candidate>.yaml → later registered use
```

```bash
cusimanse learning status <session-id>
cusimanse learning candidate <session-id> <candidate-id> <file>
cusimanse learning promote <session-id> <candidate-id> --approved
```

Promotion requires preserved evidence, replay, independent verification and explicit approval. Learning cannot mutate contracts, trusted profiles, execution boundaries or policy.

## Profiles and requirements

```text
recipes/experiments/*.yaml          researcher requirements
recipes/profiles/registry.yaml      trusted registry
recipes/profiles/host/*.yaml        reusable host capabilities
recipes/profiles/workload/*.yaml    fixed workload handlers
recipes/lima/security-research.yaml disposable compute
recipes/instrumentation/*.yaml      collectors
```

Resolution fails on no match or ambiguity.

## Policy and safety

Authoritative policy: `policies/host-policy.yaml`; evaluator: `internal/policy/`; compatibility wrapper: `scripts/policyctl`.

Credentials, unrestricted mounts, untrusted host execution, public MCP and public gateways are denied. VM creation, selected privileged actions, Git writes/push and learning promotion require approval. Evidence hashing and preservation before destruction are mandatory.

## Evidence and reproducibility

```text
runs/<session-id>/
├── session.yaml
├── evidence/audit/{events.jsonl,manifest.sha256}
├── evidence/index.yaml
├── provenance/manifest.sha256
├── analysis/summary.md
├── verification/result.md
├── research-report/{report.md,report.yaml}
├── preservation/manifest.yaml
├── observability/{token-usage.yaml,dashboard.yaml}
└── learning/
```

Model output is analysis, not raw evidence. Independent verification cites preserved evidence.

## Reference experiments

| Experiment | Purpose |
|---|---|
| `go-install-001` | disposable Linux Go baseline |
| `npm-install-001` | pinned npm install with lifecycle disabled |
| `npm-lifecycle-001` | controlled local lifecycle execution |
| `npm-threat-001` | controlled adversarial-like local lifecycle fixture |

## Validation and integration testing

Run the deterministic suite:

```bash
cusimanse doctor
cusimanse validate
cusimanse preflight
cusimanse policy validate
cusimanse test
cusimanse integration-test
```

Integration covers Go control-plane tests, project/contract/recipe validation, policy decisions, host toolchain declarations, gateway/observability configuration, Goose recipe validation, prompt/adapter handoff, role/Skill registries, capability resolution, session/evidence hashing and learning guards. Set `CUSIMANSE_RUN_VM_TEST=1` for the optional disposable Lima/QEMU smoke test.

## Repository map

```text
cmd/cusimanse/                    Go CLI/control runtime
internal/                         native Go control plane
contracts/                        research contracts
prompts/experiments/              shared experiment prompts
prompts/operators/                operator handoff guides
policies/                         declarative policy
recipes/                          experiments/profiles/host/gateway/observability/runtime
scripts/                          bootstrap/compatibility/external-tool helpers
docs/HOST-TOOLCHAIN.md            host tooling/access/configuration
 docs/GOOSE-ADAPTERS.md           Goose/Summon + adapter handoff
docs/OPERATOR-WORKFLOW.md         researcher/operator workflow
docs/RUNTIME-IMPLEMENTATION.md    runtime implementation
runs/                             research sessions and evidence
```

## Design principle

> **Researchers declare intent and requirements. Agents select and operate capabilities. Prompts standardize handoff. The Go API provides the capability boundary. Policy controls authority. Profiles define reusable infrastructure. Lima/QEMU contains execution. Evidence is preserved and independently verified.**
