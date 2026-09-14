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

The installer is idempotent and platform-aware. It installs the mandatory host stack and offers optional primary-agent adapters. It does not claim Linux-only collector names are native macOS or Windows tools; those collectors run inside the Linux Lima guest.

### 2. Check readiness

```bash
./scripts/preflight.sh
./scripts/tools.sh check
./scripts/tests/validate.sh
```

### 3. Choose the experiment

Each experiment has **two deliberately separate files**:

```text
recipes/go-install-001/recipe.yaml       ← valid Goose recipe
recipes/experiments/go-install-001.yaml  ← Cusimanse experiment configuration

recipes/npm-install-001/recipe.yaml      ← valid Goose recipe
recipes/experiments/npm-install-001.yaml ← Cusimanse experiment configuration
```

The Goose recipe contains the official Goose fields (`title`, `description`, and `instructions`) and points to the companion Cusimanse configuration. This removes the previous ambiguity between a Goose recipe and a Cusimanse configuration.

Contract = **why, scope, authorization, acceptance**. Cusimanse configuration = **experiment-specific composition**. Goose recipe = **how Goose receives/operates that experiment**. Prompt = **agent handoff convenience**.

### 4. Start the primary agent

Goose, the reference operator:

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
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

Cusimanse now provides `scripts/session.sh` for deterministic session creation, checkpoints, hashing and artifact-layout checks. Agent implementations may use it rather than relying only on prose.

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

For example, OpenCode can receive the Go prompt as a normal file-based prompt. Hermes, Antigravity and Pi use the same handoff model. The adapter transports context into the selected agent; it does not rewrite the experiment. If a selected agent lacks a capability, the run records PARTIAL/NOT_DEPLOYED rather than changing the recipe.

## Goose: native orchestration and roles

Goose is the reference operator because Cusimanse can use its native recipe, subrecipe, Skills, MCP/extension and delegation model rather than requiring an external orchestration framework.

Cusimanse specialist roles remain semantic definitions under `.agents/agents/`:

- planner
- researcher
- runtime analyst
- forensics analyst
- detection analyst
- verifier
- report generator

`recipes/agents/goose-orchestration.yaml` maps these definitions to Goose-native delegation. A role file says **what responsibility the specialist has**; the Goose orchestration recipe says **when that responsibility is delegated**. It is not another execution engine.

Typical execution:

```text
Planner / researcher
        ↓
approval + provisioning
        ↓
runtime execution
        ↓
 ┌───────────────┬──────────────┐
 runtime analyst  forensics     detection
 └───────────────┴──────────────┘
        ↓
independent verifier
        ↓
report generator
        ↓
preserve → destroy
```

Lifecycle-critical actions remain ordered. Specialist evidence analysis can run in parallel only after the relevant evidence exists. The verifier must be independent of the analysis that it verifies.

Goose-native capabilities are preferred before adding another framework: built-in Developer tools, Skills, Summon/subagent delegation and MCP extensions. Custom tools can be integrated as Goose extensions; Cusimanse records them in the recipe-scoped MCP registry.

## Agent adapters

`recipes/agents/adapter-matrix.yaml` is the compatibility source of truth.

| Agent | Integration | Native capabilities used | Status |
|---|---|---|---|
| Goose | Native Goose recipe | recipes, subrecipes, delegation, Skills, MCP/extensions | Reference |
| OpenCode | Prompt adapter | agents, plugins, MCP | Runtime validation required |
| Hermes | Prompt adapter | native tools/skills | Runtime validation required |
| Antigravity | Prompt adapter | native agents/tools | Runtime validation required |
| Pi | Prompt adapter | extensions/skills/packages | Runtime validation required |

CLI presence is not integration proof. A PASS requires a reference experiment producing session state, evidence, independent verification and a report.

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

Inspect the configured inventory:

```bash
./scripts/tools.sh list
./scripts/tools.sh versions
./scripts/tools.sh config
./scripts/tools.sh path
./scripts/tools.sh check
```

Access installed commands normally:

```bash
command -v goose
command -v limactl
command -v litellm
command -v omniroute
command -v numbat
command -v clawmetry
```

Linux-only forensic commands such as `strace`, `ss`, `ip`, `dig` and `inotifywait` are **guest instrumentation requirements**, not universal host commands. Their declared execution environment is the Lima guest.

### Optional adapters

Interactive:

```bash
./scripts/install.sh
```

Non-interactive:

```bash
CUSIMANSE_INSTALL_ADAPTERS=all ./scripts/install.sh
CUSIMANSE_INSTALL_ADAPTERS=opencode,hermes ./scripts/install.sh
```

Adapter installation metadata lives in `recipes/agents/adapter-installation.yaml`.

## Gateways and observability

Gateways and agent observability are **mandatory host capabilities**.

### Gateways

```text
OmniRoute → provider routing/fallback → LiteLLM → primary agent
```

`recipes/gateway/mandatory.yaml` declares the required services. `install.sh` installs/configures them for localhost use and credentials remain environment-only. Gateways route traffic; they do not provide VM containment.

### Observability

`recipes/observability/mandatory.yaml` declares:

- Numbat — agent/process telemetry;
- Aegis (`antropos17/Aegis`) — independent host behavioral observation;
- Phoenix/OpenTelemetry — agent tracing/telemetry;
- ClawMetry — Goose session/token visibility.

The installer prepares their local configuration and `preflight.sh` verifies the mandatory stack. Observability records behavior but does not replace Lima/QEMU isolation or authorization policy.

## Skills and MCP

`recipes/skills/registry.yaml` and `recipes/mcp/registry.yaml` define capability sources.

Goose-native Skills, delegation and MCP extensions are preferred. The registry also tracks the external Anthropic Cybersecurity Skills collection as a **candidate source**, not trusted code. Any imported skill requires provenance, scope review, replay, independent verification and human approval before promotion.

MCP credentials are environment-only and MCP cannot expand the VM/OS security boundary.

## Learning loop: controlled Voyager-style skill growth

Learning is **off by default**. It starts only after a completed report and independent verification and only after the researcher enables it in the session:

```bash
yq -i '.learning.enabled = true' runs/<session-id>/session.yaml
yq '.learning.enabled' runs/<session-id>/session.yaml
```

Then continue the primary agent with:

```text
recipes/session/learning-workflow.yaml
```

The loop accumulates verified experience as candidate skills:

```text
retrieve prior evidence/skills
        ↓
propose candidate procedure
        ↓
execute/replay in authorized environment
        ↓
evaluate → refine → replay
        ↓
independent verification
        ↓
human approval
        ↓
skills/validated/
```

This is Voyager-style **experience-to-skill accumulation**, with stronger governance. The primary agent may author the candidate, but it cannot self-approve it, mutate base contracts, grant privileges or weaken policy. The baseline loop needs no extra framework; optional learning helpers may be installed if a future workflow explicitly requires them.

## Session state and artifacts

Keep `recipes/session/session-state.yaml` as the canonical session-state contract. Every run is expected to produce:

```text
runs/<session-id>/
├── session.yaml
├── evidence/
│   ├── audit/events.jsonl
│   ├── audit/manifest.sha256
│   ├── index.yaml
│   └── <captured artifacts>/
├── provenance/manifest.sha256
├── analysis/summary.md
├── verification/result.md
├── research-report/
│   ├── report.md
│   └── report.yaml
├── preservation/manifest.yaml
├── observability/
│   ├── token-usage.yaml
│   └── dashboard.yaml
└── learning/
    ├── candidates/
    ├── evaluations/
    ├── replays/
    ├── verification/
    └── promotions/
```

`scripts/session.sh` can create/checkpoint/hash the run structure. The selected agent remains responsible for completing the substantive evidence, verification and report contents.

## Threat-model coverage and limitations

The two reference experiments prove the pipeline and exercise real observation paths, but they are **not comprehensive adversarial tests**.

Go installation exercises process, syscall, filesystem and network observation around a local Go build/install and harmless binary execution. npm installation is pinned and uses `--ignore-scripts`, so it deliberately does **not** exercise package lifecycle hooks.

The companion experiment configurations explicitly record these limitations. Future threat-model experiments should add isolated fixtures for malicious postinstall behavior, package substitution, network-policy violations and agent tool-abuse/escape attempts. Such experiments must remain authorized, disposable and independently verified.

## Validation

Static/project validation:

```bash
./scripts/tests/validate.sh
```

This validates schema shape, repository structure, recipes, adapters, registries and policy invariants without pretending a CI runner is a Lima host.

Runtime integration:

```bash
./scripts/tests/runtime.sh
```

Full disposable-VM integration:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

A runtime PASS requires actual Lima/QEMU execution and independent verification. Static validation is not runtime proof.

## Repository structure

```text
contracts/                         research intent and acceptance
prompts/experiments/                agent handoff prompts
recipes/
├── <experiment>/recipe.yaml       valid Goose recipe
├── experiments/                   Cusimanse experiment configuration
├── agents/                        adapters + Goose orchestration
├── host/                          host inventory
├── gateway/                       mandatory gateways
├── observability/                 mandatory observability
├── lima/                          Lima/QEMU profile
├── instrumentation/               guest instrumentation profile
├── session/                       session state + learning
├── skills/                        skill registry
├── mcp/                           MCP registry
└── subrecipes/                    specialist analysis/verification/reporting
.agents/agents/                     semantic specialist role definitions
.agents/skills/                     local reusable skills
scripts/install.sh                  unified host installer
scripts/install.ps1                 Windows bootstrap
scripts/session.sh                  session lifecycle/evidence helper
scripts/tools.sh                    host inventory/access
scripts/preflight.sh                readiness checks
scripts/tests/                      validation + runtime integration
runs/                               per-session evidence and reports
skills/candidate/                   candidate skills awaiting verification
skills/validated/                  approved promoted skills
```

## Safety boundary

The contract defines authorization and scope. The experiment configuration defines composition. The Goose recipe defines the agent handoff. The selected primary agent operates the workflow. Lima/QEMU plus the guest OS provide execution/isolation. Policy controls govern authorization. Instrumentation observes. Gateways route models/providers. Skills and MCP extend agent capabilities. None of the agent capability, routing or observation layers is the workload containment boundary.
