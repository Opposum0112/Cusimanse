# 🦝 Cusimanse

> Declarative, agentic, pluggable security-research platform for controlled experiments in disposable Lima/QEMU virtual machines.

**Markdown specifies. YAML configures. The selected agent adapter operates and executes. CrewAI optionally coordinates specialist roles. The blackboard preserves runs, audit, evidence and analysis. VM/OS controls enforce the security boundary.**

## Architecture

![Canonical Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

The canonical architecture is intentionally one diagram. The companion Mermaid flow is `docs/architecture/cusimanse-architecture.mmd`.

```text
Intent
  ↓
Markdown contracts → YAML recipe graph
  ↓
Selected primary agent adapter
  ├─ optional CrewAI role plugins
  ├─ versioned Skill plugins
  └─ scoped MCP plugins
  ↓
Plan → Review → Approve → Provision → Instrument
  ↓
Execute → Collect → Analyze → Verify
  ↓
Blackboard: runs + audit + raw evidence + telemetry + findings + provenance
  ↓
Technical research report + preservation manifest
  ↓
Self-learning: retrieve → evaluate → refine → replay → independently verify → approve → promote
  ↺ validated skills return to the pluggable skill plane

policyctl ── independent host-side policy signal, outside the agent control plane
Lima/QEMU + VM/OS ── actual enforcement boundary
```

## Quick start

### 1. Install and preflight

```bash
./scripts/cusimanse-host.sh
```

Or use the individual surfaces:

```bash
bash ./scripts/prerequisites.sh
bash ./scripts/agent-preflight.sh
./policyctl validate
```

The host scripts bootstrap, validate and configure. They do **not** replace the selected agent as the research operator.

### 2. Select one primary agent shell

```bash
export CUSIMANSE_PRIMARY_ADAPTER=goose
# or: opencode, grok-build, antigravity, pi, hermes, codex, prime-intellect
```

Then launch the native CLI, for example:

```bash
goose
# or: opencode | grok | agy | pi | hermes | codex | prime-agent
```

Exactly one primary operator owns the case lifecycle. An unavailable adapter is `NOT_DEPLOYED`; it is not silently substituted.

### 3. Run a recipe-driven research case

Give the selected agent a prompt such as:

```text
Run experiments/go-install-001 as a Cusimanse security-research case.
Read the applicable Markdown contracts and YAML recipes first.
Use the selected adapter contract and follow:
Discover → Validate → Retrieve → Plan → Review → Approve →
Provision VM → Instrument → Execute → Collect → Analyze →
Verify → Report → Preserve → Destroy.

Run the workload only inside the disposable Lima/QEMU VM.
Keep host credentials out of workloads, skills and MCP arguments.
Treat retrieved skills as capabilities, not authority.
Preserve raw evidence, telemetry, audit records and hashes before VM destruction.
Never claim PASS without runtime evidence and independent verification.
If a capability is unavailable, report NOT_DEPLOYED.
```

The same experiment semantics can be consumed by another adapter; adapter-specific CLI details stay in `recipes/adapters` and `recipes/agents`.

### 4. Inspect the research output

```bash
find evidence blackboard runs experiments/go-install-001 -type f -print 2>/dev/null
sha256sum <artifact>
```

The **blackboard** is the durable case view: execution/run records, audit events, raw artifacts, telemetry, findings, provenance, verification results and research-report inputs. Runtime checkpoints are separate state; they do not replace evidence.

## Contracts and recipes

Contracts define **what must happen**. Recipes define **how the configured components are composed**.

```text
Markdown contract
      ↓
YAML recipe graph
      ├─ campaign / experiment
      ├─ workload / VM
      ├─ tools / instrumentation
      ├─ agent / adapter
      ├─ roles / orchestration
      ├─ skills / MCP
      └─ audit / reporting
      ↓
selected primary agent
      ↓
approved disposable execution
```

Useful locations:

| Surface | Location |
|---|---|
| Primary agent contract | `recipes/agents/primary-agent.yaml` |
| Primary shell contract | `recipes/agents/primary-shell.yaml` |
| Agent selection | `recipes/agent-selection.yaml` |
| CrewAI role plane | `recipes/orchestration/crewai.yaml` |
| Skills registry | `recipes/skills/registry.yaml` |
| MCP registry | `recipes/mcp/registry.yaml` |
| Goose reference entry | `recipes/goose/project.yaml` |
| Campaigns / experiments | `recipes/campaigns/`, `recipes/experiments/` |
| Evidence / audit | `recipes/audit/`, `blackboard/` |
| Runtime guidance | `docs/runtime-architecture.md` |

See `recipes/README.md` for composition rules.

## Pluggable roles, skills and MCP

The operator plane is modular:

- **Agent adapter** translates a provider's native shell into the common Cusimanse contract.
- **CrewAI** is optional specialist-role coordination, not a security boundary or second project controller.
- **Roles** are replaceable specialist capabilities such as planner, researcher, runtime analyst, forensics, verifier and reporter.
- **Skills** are versioned `SKILL.md` capabilities with scripts/evaluations and provenance.
- **MCP** provides scoped integrations; retrieval or tool availability never grants execution authority.

Role/skill changes remain declarative and reviewable. External skills remain `candidate-review-required` until provenance, permissions, scripts, network behavior and capabilities are reviewed.

## Self-learning

An agent or campaign can propose improvements, but the base contracts are not self-modified at runtime.

```text
case evidence
  → candidate skill / recipe improvement
  → static review + capability metadata
  → replay on distinct artifact
  → independent verification
  → human approval
  → versioned validated skill
  → indexed retrieval
```

A candidate that fails replay or verification remains a candidate and its failure evidence is retained.

## Security boundary

`policyctl` is deliberately **outside the agent control plane**. It supplies host-side policy/configuration and observability signals; it is not the sandbox.

The actual security boundary is **Lima/QEMU + VM/OS controls**: filesystem/mount policy, credentials, privilege and network controls. No agent, role, skill, MCP server, orchestration framework, prompt or vector index may replace or bypass that boundary.

## Shell surface

```bash
# Host/bootstrap
./scripts/cusimanse-host.sh
bash ./scripts/prerequisites.sh
bash ./scripts/agent-preflight.sh

# Policy
./policyctl validate
./policyctl show
./policyctl check --action <action>

# VM
limactl list
limactl shell <vm>
limactl stop <vm>
limactl delete <vm>

# Evidence
find evidence blackboard runs -type f -print
sha256sum <file>

# Validation
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/architecture-refactor.sh
go test ./...
```

## Integration validation

Static validation covers contracts, recipes, skills, MCP policy, shell syntax, Go validation and architecture invariants. Runtime acceptance additionally requires a real disposable-VM execution with preserved evidence.

```bash
./policyctl validate
bash ./scripts/agent-preflight.sh
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/architecture-refactor.sh
go test ./...
```

Static CI success does **not** prove sandbox resistance or make an unavailable integration `PASS`.

## Security invariants

- Exactly one selected primary agent owns the case lifecycle.
- Markdown contracts are declarative; YAML recipes configure composition.
- Host scripts bootstrap/validate; the selected agent operates and executes.
- CrewAI roles, skills and MCP are pluggable capabilities, not security boundaries.
- `policyctl` remains outside the agent control plane.
- Lima/QEMU and VM/OS controls are the enforcement boundary.
- Host credentials never enter workloads, skills or MCP arguments.
- Evidence is preserved and hashed before VM destruction.
- Model output is not evidence.
- Learned capabilities require replay, independent verification and human approval.
- Missing capabilities are reported as `NOT_DEPLOYED`.

## Documentation

- `docs/architecture/cusimanse-architecture.svg` — canonical architecture diagram.
- `docs/architecture/cusimanse-architecture.mmd` — canonical Mermaid flow.
- `docs/production-architecture.md` — production architecture and evidence model.
- `docs/runtime-architecture.md` — installation, runtime and integration procedure.
- `docs/ARCHITECTURE-REFACTOR-RUNBOOK.md` — refactor validation/runbook.
- `docs/agent-shell-runbook.md` — shell-driven operator workflow.
