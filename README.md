# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-neutral security research with AI agents.** The experiment recipe is the source of truth for the contract, host tools, Lima VM, instrumentation, workload, evidence, verification, report and learning settings. **Goose is the reference primary operator**; other validated primary agents use the same recipe through an adapter/prompt handoff.

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

## Researcher workflow

### 1. Install the host once

From the repository root:

```bash
./scripts/install.sh
```

The installer reads the declared host inventory from `recipes/host/security-research.yaml` and installs/configures the complete required host stack: Goose, Lima/QEMU, Go, Node/npm, forensic/network tools, LiteLLM, OmniRoute, Numbat, Aegis, Phoenix/OpenTelemetry and ClawMetry.

### 2. Validate the host and repository

```bash
./scripts/preflight.sh
./scripts/tests/validate.sh
```

Do not start an experiment until preflight passes.

### 3. Select a contract and experiment recipe

Reference experiments:

```text
contracts/go-install-001.md     → recipes/go-install-001/recipe.yaml
contracts/npm-install-001.md   → recipes/npm-install-001/recipe.yaml
```

The contract defines **what/why**. The YAML recipe defines **how**. The recipe remains agent-neutral.

### 4. Start the primary agent manually

Goose reference examples:

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
```

For another validated primary agent, hand it the same experiment recipe through its supported adapter/prompt path.

### 5. Let the recipe and agent execute the workload

The researcher **does not run workload commands manually on the host**. The primary agent operates the recipe and executes the workload inside the disposable Lima/QEMU VM.

The agent handles:

1. session creation from `recipes/session/session-state.yaml`;
2. scope and approval checks;
3. Lima VM provisioning;
4. instrumentation startup;
5. recipe-defined workload execution inside the VM;
6. evidence collection and session checkpoints;
7. specialist analysis/forensics/verification;
8. research report generation;
9. evidence/provenance preservation and VM destruction.

### 6. Review the results

```bash
cat runs/<session-id>/research-report/report.md
cat runs/<session-id>/verification/result.md
cat runs/<session-id>/analysis/summary.md
cat runs/<session-id>/evidence/index.yaml
cat runs/<session-id>/session.yaml
```

The primary researcher output is `runs/<session-id>/research-report/report.md`.

## Architecture

```text
Researcher → Contract → Agent-neutral Experiment Recipe
                              ↓
                     Primary Agent
                  Goose / validated adapter
                              ↓
             Native planning + specialist roles
                Skills + MCP + subrecipes
                              ↓
                Lima/QEMU disposable VM
                              ↓
                 Instrumentation profile
                              ↓
               Recipe-defined workload
                              ↓
                  Evidence + session.yaml
                              ↓
               Analysis → Verification
                              ↓
                    Research Report
                              ↓
                Preserve → Destroy VM
                              ↓
                 Optional Learning
```

Editable Mermaid source:

```text
docs/architecture/cusimanse-architecture.mmd
```

## Host tools: configuration and access

Host tools are declared in `recipes/host/security-research.yaml` and installed/configured by `scripts/install.sh`. Do not maintain a second inventory.

Inspect the complete declared host toolchain:

```bash
./scripts/tools.sh list
./scripts/tools.sh versions
./scripts/tools.sh config
./scripts/tools.sh path
./scripts/tools.sh check
```

Installed commands are available directly from the shell:

```bash
goose --help
limactl --help
qemu-system-x86_64 --version
go version
node --version
npm --version
litellm --help
omniroute --help
numbat --help
clawmetry --help
jq --version
yq --version
rg --version
strace --version
tcpdump --version
lsof -v
```

Find any executable with:

```bash
command -v <tool>
```

Cusimanse uses `~/.local/bin` and `~/go/bin`; Python gateway/telemetry packages are in `~/.local/share/cusimanse/venv/`.

Gateway and agent-observability components are **mandatory host capabilities**, not optional experiment layers. Their local configuration is created by the installer from the repository declarations; secrets stay in environment files.

## Execution and instrumentation

Every reference experiment uses:

- `recipes/lima/security-research.yaml` — Lima/QEMU disposable VM.
- `recipes/instrumentation/security-research.yaml` — process, syscall, network, DNS and filesystem instrumentation.
- The experiment recipe — workload and experiment-specific composition.
- `recipes/session/session-state.yaml` — durable per-run state contract.

**Container Use may be added** for an additional containerized environment, but it does not replace the Lima/QEMU experiment boundary.

## Session state and artifacts

Keep `recipes/session/session-state.yaml`. Each experiment creates:

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

`session.yaml` records immutable experiment identity, selected profiles, lifecycle checkpoints, approvals, evidence, verification, reporting, mandatory host gateway/observability state and learning state.

## Learning workflow — explicitly enabled

Learning is **disabled by default** and never starts automatically when an experiment ends.

After `report.md` and independent verification are complete:

1. Enable learning for that run:

```bash
yq -i '.learning.enabled = true' runs/<session-id>/session.yaml
yq '.learning.enabled' runs/<session-id>/session.yaml
```

The second command must print `true`.

2. Manually continue the primary agent and give it:

```text
recipes/session/learning-workflow.yaml
```

3. The agent performs:

```text
retrieve → propose → execute → evaluate → refine → replay
→ independent verification → human approval → promote
```

4. Review candidates:

```bash
find runs/<session-id>/learning -maxdepth 3 -type f -print
```

5. Only an explicitly approved candidate may be promoted to:

```text
skills/validated/
```

Learning execution that needs compute uses the same disposable Lima VM controls. Learning cannot mutate base contracts, grant privileges or weaken security policy automatically.

The learning contract is `recipes/session/learning-workflow.yaml`; its `enabled.default` is `false` and its `session_key` is `learning.enabled`.

## Validation and integration

```bash
./scripts/tests/validate.sh
./scripts/tests/runtime.sh
```

For a real disposable-VM integration test:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

A runtime PASS requires actual Lima/QEMU execution and independent verification. Static validation alone is not runtime proof.

## Repository structure

```text
contracts/                         research intent and acceptance
recipes/                           authoritative YAML configuration
├── go-install-001/                Go experiment
├── npm-install-001/               npm experiment
├── host/                          mandatory host inventory
├── gateway/                       mandatory gateway declaration
├── observability/                 mandatory observability declaration
├── lima/                          Lima/QEMU profile
├── instrumentation/               instrumentation profile
├── session/                       session state + learning workflow
└── subrecipes/                    specialist analysis/verification/reporting
.agents/
├── agents/                        specialist role definitions
└── skills/                        reusable agent skills
scripts/
├── install.sh                     unified host installation/configuration
├── preflight.sh                   host readiness
├── tools.sh                       host tool inventory/access
└── tests/                         validation + runtime integration
docs/architecture/                 canonical SVG + Mermaid architecture
docs/images/                      mascot/logo and architecture artwork
packages/labprobe/                 reference Go workload
runs/                              per-session evidence and reports
skills/validated/                  human-approved promoted skills
```

## Safety boundary

The contract defines authorization and research scope. The recipe defines the experiment. The primary agent operates it. Lima/QEMU plus the guest OS provide the execution/isolation boundary. Instrumentation observes the VM. Gateways route model/provider traffic. Observability records behavior. Routing and observation components are not the workload containment boundary.
