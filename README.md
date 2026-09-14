# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-neutral security research on disposable compute.** The experiment recipe is the source of truth. **Goose is the reference native operator**, while OpenCode, Hermes, Antigravity and Pi can drive the same experiment through validated adapters and the prompt library.

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

## System requirements

| Requirement | Reference |
|---|---|
| OS | Linux, macOS, Windows 10/11; Windows experiments use the supported native/WSL2 compatibility path |
| Shell | Bash for the canonical installer; PowerShell shim is provided for Windows |
| CPU/RAM | 4+ CPU cores and 8+ GB RAM recommended for VM + observability workloads |
| Disk | 20+ GB free recommended; experiments and evidence consume additional space |
| VM | Lima + QEMU; guest OS provides the execution/isolation boundary |
| Runtime | Python 3, Node.js 22+, npm, Go |
| Required agent | Goose CLI |
| Required host services | LiteLLM + OmniRoute gateways; Numbat + Aegis + Phoenix/OpenTelemetry + ClawMetry observability |
| Network | Internet access for initial installation and any recipe-declared package/model traffic; experiment networking remains recipe/policy controlled |

Exact versions and commands are declared by `recipes/host/security-research.yaml`.

## Researcher quick start

### 1. Prepare the host

Linux/macOS/WSL2:

```bash
./scripts/install.sh
```

Native Windows:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

The installer is designed to be idempotent and distro-neutral. It installs the mandatory host stack and offers optional primary-agent adapters. Existing tools are reused. Unsupported optional capabilities are reported rather than silently substituted.

### 2. Check readiness

```bash
./scripts/preflight.sh
./scripts/tools.sh check
./scripts/tests/validate.sh
```

### 3. Choose the experiment

```text
contracts/go-install-001.md    → recipes/go-install-001/recipe.yaml
contracts/npm-install-001.md  → recipes/npm-install-001/recipe.yaml
```

Contract = **what/why**. Recipe = **authoritative how**. Prompt = **agent handoff**.

### 4. Start the primary agent

Goose, the reference operator:

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
```

Or choose another installed adapter and give it the corresponding prompt from:

```text
prompts/experiments/
```

The same contract and experiment recipe remain authoritative.

### 5. Let the agent run the experiment

The researcher **does not run workload commands manually on the host**. The recipe and primary agent perform the workload inside the disposable Lima VM. The agent provisions the VM, starts instrumentation, executes the recipe workload, collects evidence, delegates analysis/verification, writes the report and preserves evidence before destroying the VM.

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

The prompt library is a **handoff layer**, not a second source of experiment truth.

```text
Contract + Recipe + Prompt reference
                 ↓
        selected primary agent
       ┌─────────┼──────────┐
     Goose    OpenCode   Hermes / Antigravity / Pi
       ↓          ↓              ↓
 native tools / plugins / skills / MCP / delegation
                 ↓
        same recipe + Lima VM
                 ↓
        same evidence + report
```

For another agent:

1. install its adapter from `scripts/install.sh`;
2. start the agent in the repository;
3. open `prompts/experiments/<experiment>.md`;
4. provide that prompt to the agent;
5. require it to read the contract and recipe;
6. let the agent execute the recipe-defined workload in Lima;
7. review the same `runs/<session-id>/` artifacts.

An adapter must not rewrite the recipe. If the selected agent lacks a required native capability, the run records that capability as unsupported/PARTIAL rather than changing the experiment.

## Goose: native orchestration and roles

Goose is intentionally the reference operator because its current native model supports reusable recipes, subrecipes, Skills and MCP extensions. Its **Summon** extension can load recipes/agents/subrecipes and delegate tasks to subagents; recipes containing `sub_recipes` can use Summon automatically. Its Skills extension loads reusable filesystem skills, while MCP-based extensions provide tools/resources. citeturn3search1turn3search3turn3search0

Cusimanse keeps specialist roles in `.agents/agents/`:

- planner
- researcher
- runtime analyst
- forensics analyst
- detection analyst
- verifier
- report generator

`recipes/agents/goose-orchestration.yaml` maps these semantic roles to Goose-native delegation. Roles are **definitions**, not another infrastructure layer. Goose decides when to delegate; lifecycle-critical stages remain ordered and independent verification remains mandatory.

Typical execution:

```text
Plan
  ↓
Approval
  ↓
Provision VM → Start instrumentation
  ↓
Execute workload
  ↓
Evidence collection
  ├── runtime analysis
  ├── forensics
  └── detection analysis       ← independent work may run in parallel
  ↓
Independent verifier
  ↓
Report generator
  ↓
Preserve → Destroy VM
```

Goose built-in Developer, Skills, Summon and Extension Manager capabilities are preferred before adding an external framework. Custom Goose extensions are MCP servers and can be added through `goose configure` or the recipe-scoped MCP registry. citeturn3search0turn3search2turn3search4

## Agent adapters

`recipes/agents/adapter-matrix.yaml` is the authoritative compatibility matrix.

| Agent | Cusimanse integration | Native capability used | Status semantics |
|---|---|---|---|
| Goose | Native recipe | recipes + subrecipes + Summon + Skills + MCP/extensions | Reference |
| OpenCode | Prompt adapter | native agents/plugins/MCP | Runtime validation required |
| Hermes | Prompt adapter | native tools/skills | Runtime validation required |
| Antigravity | Prompt adapter | native agent orchestration/tools | Runtime validation required |
| Pi | Prompt adapter | native extensions/skills/packages | Runtime validation required |

CLI presence is not integration proof. A validated adapter must complete a reference experiment and produce session state, evidence, independent verification and report artifacts.

Adapter implementation and install metadata live under `recipes/agents/`. Native plugins/extensions are preferred; a thin adapter is only the transport into the agent.

## Host tools and configuration

Host tooling is declarative:

```text
recipes/host/security-research.yaml
              ↓
      scripts/install.sh
              ↓
 installed tools + local config
              ↓
      scripts/preflight.sh
```

Inspect everything installed/declared:

```bash
./scripts/tools.sh list
./scripts/tools.sh versions
./scripts/tools.sh config
./scripts/tools.sh path
./scripts/tools.sh check
```

Access individual commands normally:

```bash
command -v goose
command -v limactl
command -v qemu-system-x86_64
command -v litellm
command -v omniroute
command -v numbat
command -v clawmetry
```

The installer adds `~/.local/bin` and `~/go/bin` to PATH. Python gateway/telemetry packages are kept in `~/.local/share/cusimanse/venv/`.

### Installing optional adapters

Interactive:

```bash
./scripts/install.sh
```

The installer asks whether to add OpenCode, Hermes, Antigravity or Pi. For automation:

```bash
CUSIMANSE_INSTALL_ADAPTERS=all ./scripts/install.sh
```

or:

```bash
CUSIMANSE_INSTALL_ADAPTERS=opencode,hermes ./scripts/install.sh
```

The adapter installation recipe records platform-specific commands and fallback behavior. Optional adapter failure does not weaken the mandatory Goose/host requirements.

## Gateways and observability

Gateways and agent observability are **mandatory host capabilities**.

### Gateways

`recipes/gateway/mandatory.yaml` declares:

```text
OmniRoute  → provider routing/fallback
    ↓
LiteLLM    → model gateway/normalization
    ↓
Primary agent
```

`install.sh` installs/configures both locally and binds them to localhost by default. Credentials remain environment-only. Gateways route model/provider traffic; they are **not** the VM security boundary.

### Observability

`recipes/observability/mandatory.yaml` declares the host observation stack:

- Numbat — agent/process telemetry;
- Aegis (`antropos17/Aegis`) — independent host-level behavioral observation;
- Phoenix/OpenTelemetry — agent traces/telemetry;
- ClawMetry — Goose session/token visibility.

The installer installs/configures the stack and `preflight.sh` verifies it. Observers record behavior but do not replace Lima/QEMU isolation or policy controls.

## Skills and MCP

`recipes/skills/registry.yaml` and `recipes/mcp/registry.yaml` define reusable capability sources.

Goose-native Skills, Summon and MCP extensions are preferred. The registry also tracks the external **Anthropic Cybersecurity Skills** collection as a candidate source. External skills are never trusted merely because they are discoverable: they require provenance, scope review, replay, independent verification and human approval before promotion. citeturn0search11

MCP is recipe-scoped and credentials are environment-only. New MCP/extension integrations require approval. MCP/Skills do not expand the VM/OS security boundary.

## Learning loop: controlled Voyager-style skill growth

Learning is **off by default**. It begins only after a completed report and independent verification and only when the researcher explicitly sets:

```bash
yq -i '.learning.enabled = true' runs/<session-id>/session.yaml
yq '.learning.enabled' runs/<session-id>/session.yaml
```

Then manually continue the primary agent with:

```text
recipes/session/learning-workflow.yaml
```

The loop is inspired by Voyager-style experience-to-skill accumulation, but Cusimanse adds explicit governance:

```text
retrieve prior skills/evidence
        ↓
propose reusable skill
        ↓
execute/replay in authorized environment
        ↓
evaluate
        ↓
refine
        ↓
replay on separate evidence/case
        ↓
independent verification
        ↓
human approval
        ↓
promote → skills/validated/
```

The primary agent extracts a reusable procedure from verified experience. It does **not** silently rewrite base contracts, grant privileges or weaken policy. Optional Taskflow/LangGraph helpers may be installed by the same interactive installer if a learning workflow actually needs them; native Goose capabilities are preferred and no additional learning tool is required for the baseline loop.

## Session state and researcher artifacts

Keep `recipes/session/session-state.yaml` as the canonical session-state contract. Every run produces:

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

## Validation

Static validation:

```bash
./scripts/tests/validate.sh
```

Runtime integration:

```bash
./scripts/tests/runtime.sh
```

Full disposable-VM integration:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

Runtime PASS requires actual Lima/QEMU execution and independent verification.

## Repository structure

```text
contracts/                         research intent and acceptance
prompts/experiments/                agent handoff prompts
recipes/                            authoritative YAML
├── agents/                         adapter matrix + Goose orchestration
├── host/                           host tool inventory
├── gateway/                        mandatory gateways
├── observability/                  mandatory observability
├── lima/                           Lima/QEMU profile
├── instrumentation/                instrumentation profile
├── session/                        session state + learning
├── skills/                         skill registry
├── mcp/                            MCP registry
└── subrecipes/                     specialist analysis/verification/reporting
.agents/agents/                     semantic specialist role definitions
.agents/skills/                     local reusable skills
scripts/install.sh                  unified host installer
scripts/install.ps1                 Windows installer shim
scripts/tools.sh                    host inventory/access
scripts/preflight.sh                readiness checks
scripts/tests/                      validation + runtime integration
runs/                               per-session evidence and reports
skills/validated/                   approved promoted skills
```

## Safety boundary

The contract defines authorization and scope. The recipe defines the experiment. The selected primary agent operates it. Lima/QEMU plus the guest OS provide execution/isolation. Policy controls govern authorization. Instrumentation observes. Gateways route models/providers. Skills and MCP extend agent capabilities. None of the agent capability, routing or observation layers is the workload containment boundary.
