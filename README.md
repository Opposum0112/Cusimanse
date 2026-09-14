# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-neutral security research on disposable compute.** The Cusimanse experiment recipe is the source of truth. **Goose is the reference native operator**, while OpenCode, Hermes, Antigravity and Pi can drive the same experiment through validated adapters and the prompt library.

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

## System requirements

| Requirement | Reference |
|---|---|
| OS | Linux; macOS with Lima/QEMU; Windows 10/11 through WSL2 for full experiments |
| Shell | Bash for the canonical installer; PowerShell bootstrap for Windows |
| CPU/RAM | 4+ CPU cores and 8+ GB RAM recommended |
| Disk | 20+ GB free recommended, plus evidence space |
| VM | Lima + QEMU; guest OS is the execution/isolation boundary |
| Runtime | Python 3, Node.js 22+, npm, Go, yq |
| Required agent | Goose CLI |
| Required host services | LiteLLM + OmniRoute; Numbat + Aegis + Phoenix/OpenTelemetry + ClawMetry |
| Network | Internet for installation and recipe-declared package/model traffic; experiment traffic remains policy/recipe controlled |

Native Windows without WSL2 is an **agent-only fallback**, not a full Cusimanse experiment host. Apple Silicon can use native arm64 Lima/QEMU; x86_64 QEMU is not required for native arm64 experiments.

## Researcher quick start

### 1. Prepare the host

Linux/macOS/WSL2:

```bash
./scripts/install.sh
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

The installer is idempotent and platform-aware. It installs/configures the mandatory host stack and offers optional primary-agent adapters. It does not claim Linux-only collector names are native macOS or Windows tools; those collectors run inside the Linux Lima guest.

### 2. Check readiness

```bash
./scripts/preflight.sh
./scripts/tools.sh check
./scripts/tests/validate.sh
```

### 3. Choose the experiment

Each reference experiment has **two deliberately separate files**:

```text
recipes/go-install-001/recipe.yaml       ← valid Goose recipe
recipes/experiments/go-install-001.yaml  ← Cusimanse experiment configuration

recipes/npm-install-001/recipe.yaml      ← valid Goose recipe
recipes/experiments/npm-install-001.yaml ← Cusimanse experiment configuration

recipes/npm-threat-001/recipe.yaml       ← valid Goose threat-model recipe
recipes/experiments/npm-threat-001.yaml  ← controlled adversarial experiment configuration
```

The Goose recipe contains the official Goose fields (`title`, `description`, and `instructions`) and points to the companion Cusimanse configuration. The experiment configuration is intentionally **not** a Goose recipe.

Contract = **why, scope, authorization, acceptance**. Cusimanse configuration = **experiment-specific composition**. Goose recipe = **how Goose receives/operates that experiment**. Prompt = **agent handoff convenience**.

### 4. Start the primary agent

Goose, the reference operator:

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-threat-001/recipe.yaml --interactive
```

The agent reads the companion experiment configuration and contract. The researcher starts the agent; the agent operates the lifecycle.

### 5. Let the agent run the experiment

The researcher **does not run workload commands manually on the host**. The experiment configuration declares the workload and the agent executes it inside disposable Lima compute.

The supported lifecycle is:

```text
create session → validate → preflight → plan → approval
→ provision VM → start instrumentation → execute workload
→ collect/hash evidence → analyze → independently verify
→ report → preserve → destroy VM
```

Cusimanse provides `scripts/session.sh` for deterministic session creation, checkpoints, hashing and artifact-layout checks. `scripts/run-experiment.sh` performs the deterministic VM/evidence portion so the agent is not expected to improvise lifecycle mechanics.

### 6. Review the result

```bash
cat runs/<session-id>/research-report/report.md
cat runs/<session-id>/verification/result.md
cat runs/<session-id>/analysis/summary.md
cat runs/<session-id>/evidence/index.yaml
cat runs/<session-id>/session.yaml
```

`research-report/report.md` is the primary researcher output.

## Prompt-driven operation with other agents

The prompt library is a **handoff layer**, not a second experiment definition. This permits the same contract and Cusimanse configuration to be driven by a primary agent other than Goose.

For another agent:

1. install the adapter from `scripts/install.sh`;
2. select the experiment recipe/configuration;
3. open `prompts/experiments/<experiment>.md`;
4. give that prompt to the selected agent;
5. require the agent to read the contract and companion experiment configuration;
6. let it execute the same workload inside Lima;
7. review the same session artifacts.

If a selected agent lacks a capability, the run records PARTIAL/NOT_DEPLOYED rather than changing the recipe.

## Goose: native orchestration and roles

Goose is the reference operator because Cusimanse can use its native recipe, subrecipe, Skills, MCP/extension and delegation model rather than requiring an external orchestration framework.

Cusimanse specialist roles remain semantic definitions under `.agents/agents/`: planner, researcher, runtime analyst, forensics analyst, detection analyst, verifier and report generator.

`recipes/agents/goose-orchestration.yaml` maps these definitions to Goose-native delegation. A role file says **what responsibility the specialist has**; the Goose orchestration recipe says **when that responsibility is delegated**. It is not another execution engine.

Lifecycle-critical actions remain ordered. Specialist evidence analysis can run in parallel only after the relevant evidence exists. The verifier must be independent of the analysis that it verifies.

Goose-native capabilities are preferred before adding another framework: built-in Developer tools, Skills, Summon/subagent delegation and MCP extensions. Custom tools can be integrated as Goose extensions; Cusimanse records them in the recipe-scoped MCP registry.

## Agent adapters

`recipes/agents/adapter-matrix.yaml` declares compatibility. `recipes/agents/adapter-validation.yaml` records actual validation status separately.

| Agent | Integration | Status |
|---|---|---|
| Goose | Native Goose recipe | Reference; runtime PASS requires actual integration evidence |
| OpenCode | Prompt adapter | NOT_DEPLOYED |
| Hermes | Prompt adapter | NOT_DEPLOYED |
| Antigravity | Prompt adapter | NOT_DEPLOYED |
| Pi | Prompt adapter | NOT_DEPLOYED |

CLI presence or recipe compatibility is never a PASS. Promotion requires disposable-VM execution, session artifacts and independent verification.

## Host tools and configuration

Host tooling is declarative:

```text
recipes/host/security-research.yaml
              ↓
      scripts/install.sh
              ↓
 installed tools + local configuration
              ↓
      scripts/preflight.sh
```

Linux-only forensic commands such as `strace`, `ss`, `ip`, `dig` and `inotifywait` are **guest instrumentation requirements**, not universal host commands. Their declared execution environment is the Lima guest. Platform preflight selects only host capabilities appropriate to the current OS/architecture.

## Gateways and observability

Gateways and agent observability are configured as mandatory integrations for a full research deployment, but they are **not the containment boundary** and are not required for CI control-plane validation. They are configured for localhost use; credentials remain environment-only.

`recipes/gateway/mandatory.yaml` declares gateways. `recipes/observability/mandatory.yaml` declares Numbat, Aegis, Phoenix/OpenTelemetry and ClawMetry. The VM workload remains isolated from these host integrations.

## Skills and MCP

`recipes/skills/registry.yaml` and `recipes/mcp/registry.yaml` define capability sources.

Goose-native Skills, delegation and MCP extensions are preferred. External skill collections are candidate sources, not trusted code. Imported skills require provenance, scope review, replay, independent verification and human approval before promotion.

MCP credentials are environment-only and MCP cannot expand the VM/OS security boundary.

## Learning loop

Learning is **off by default**. It starts only after a completed report and independent verification and only after the researcher enables it in the session. Candidate skills require replay, independent verification and human approval before promotion to `skills/validated/`.

## Session state and artifacts

Keep `recipes/session/session-state.yaml` as the canonical session-state contract. Every run is expected to produce session state, immutable evidence plus hashes, analysis, independent verification, report and preservation metadata. `scripts/session.sh` implements the lifecycle state machine and evidence/provenance hashing.

## Threat-model coverage and limitations

The reference experiments now separate **pipeline baselines** from a **controlled adversarial fixture**:

- `go-install-001`: Go build/install and harmless execution with process, syscall, filesystem and network observation.
- `npm-install-001`: pinned package installation with `--ignore-scripts`; this is a clean baseline and intentionally does not run lifecycle hooks.
- `npm-lifecycle-001`: controlled local postinstall fixture that writes a marker and attempts a localhost connection.
- `npm-threat-001`: explicitly threat-model-oriented version of the controlled fixture, exercising postinstall process/filesystem behavior and localhost-network observation while remaining local, deterministic and disposable.

The npm fixture is intentionally **adversarial-like, not real malware**. It never receives credentials and is not authorized for external network access. Package substitution, network-policy violations and agent tool-abuse/escape remain separate future experiments rather than being falsely claimed as covered.

## Validation

Static/project validation:

```bash
./scripts/tests/validate.sh
```

This validates Goose schema shape, experiment composition, adapters, threat-model declarations, registries and policy invariants without requiring Lima or third-party observability services on the CI runner.

Functional control-plane validation:

```bash
./scripts/tests/runtime.sh
```

This exercises actual Goose recipe validation plus the session lifecycle, invalid-transition rejection, audit events and evidence/provenance hashing.

Full disposable-VM integration:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

A VM runtime PASS means the Lima/QEMU smoke test executed. An experiment/adaptor PASS additionally requires the session's independent verification artifacts; static validation is never runtime proof.

## Safety boundary

The contract defines authorization and scope. The experiment configuration defines composition. The Goose recipe defines the agent handoff. The selected primary agent operates the workflow. Lima/QEMU plus the guest OS provide execution/isolation. Policy controls govern authorization. Instrumentation observes. Gateways route models/providers. Skills and MCP extend agent capabilities. None of the agent capability, routing or observation layers is the workload containment boundary.
