# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.webp)

**Declarative security research with AI agents.** The experiment recipe is the source of truth: it defines the contract references, Lima VM, instrumentation profile, workload, evidence, verification, report and optional learning. **Goose is the reference primary operator**, while the same recipe can be handed to another validated primary agent through an adapter/prompt.

![Cusimanse architecture](docs/images/cusimanse-architecture.webp)

## Researcher: run an experiment

### 1. Prepare the host once

From the repository root:

```bash
./scripts/install.sh
```

This installs the complete declared host toolchain from `recipes/host/security-research.yaml`, including Goose, Lima/QEMU, Go/Node/npm, forensic tools, LiteLLM, OmniRoute, Numbat, Aegis, Phoenix/OpenTelemetry and ClawMetry. The script also writes the local gateway, observability and Goose configuration under `~/.config/cusimanse/`.

Load the Goose environment:

```bash
source ~/.config/cusimanse/goose.env
```

Check the installation:

```bash
./scripts/preflight.sh
./scripts/tools.sh list
./scripts/tools.sh versions
```

To see the installed configuration locations without printing secrets:

```bash
./scripts/tools.sh config
```

Host tools are configured through the YAML host recipe; `scripts/install.sh` implements that declaration. Do not create a second host-tool configuration file. Tools installed into `~/.local/bin` and `~/go/bin` are directly available on `PATH` after the environment is loaded.

### 2. Validate the project

```bash
./scripts/tests/validate.sh
```

This validates shell scripts, YAML/recipe structure, required profiles, session state, mandatory gateway/observability declarations, stale references and repository invariants.

### 3. Start the experiment

Choose a reference experiment and launch its Goose recipe:

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
```

or:

```bash
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
```

**The researcher does not manually run the workload commands.** The selected recipe tells the primary agent what to provision, instrument and execute. The agent executes the recipe-defined workload inside the disposable Lima VM and records the results.

### 4. What the agent executes for Go

The Go experiment recipe executes inside the VM:

```bash
go version
go install ./packages/labprobe
```

### 5. What the agent executes for npm

The npm experiment recipe executes inside the VM:

```bash
node --version
npm --version
mkdir -p /tmp/npm-test
cd /tmp/npm-test
npm init -y
npm install lodash@4.17.21 --ignore-scripts
```

These commands are workload definitions, not researcher host commands.

### 6. Review the result

The primary output is:

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
└── observability/
    ├── token-usage.yaml
    └── dashboard.yaml
```

Read the researcher-facing result in this order:

```bash
cat runs/<session-id>/research-report/report.md
cat runs/<session-id>/verification/result.md
cat runs/<session-id>/analysis/summary.md
cat runs/<session-id>/evidence/index.yaml
cat runs/<session-id>/session.yaml
```

The report must distinguish observed facts, analysis/inference and independent verification. Model output is never evidence.

## How the recipe and agent work

```text
Researcher
   ↓
Contract
   ↓
Agent-neutral experiment recipe
   ↓
Primary agent (Goose reference)
   ├── Plan / Todo
   ├── Skills
   ├── Specialist subagents / subrecipes
   └── MCP / Developer tools
   ↓
Disposable Lima/QEMU VM
   ↓
Instrumentation profile
   ↓
Recipe-defined workload
   ↓
Evidence + session.yaml
   ↓
Analysis → independent verification
   ↓
Research report
   ↓
Preserve → destroy VM
```

Specialist role definitions remain available under `.agents/agents/` and are delegated by the primary agent. No second orchestration controller is required.

## Host tool configuration and access

The authoritative host inventory is:

```text
recipes/host/security-research.yaml
```

The installer is:

```bash
./scripts/install.sh
```

The host check is:

```bash
./scripts/preflight.sh
```

The complete installed-tool inventory is:

```bash
./scripts/tools.sh list
```

Tool versions are:

```bash
./scripts/tools.sh versions
```

Local configuration paths are:

```bash
./scripts/tools.sh config
```

The gateway configuration is under `~/.config/cusimanse/`. Observability configuration is under the same directory. Provider credentials are supplied through the environment and are never committed to Git.

## Execution and instrumentation

Every reference experiment uses:

- `recipes/lima/security-research.yaml` for the disposable Lima/QEMU VM.
- `recipes/instrumentation/security-research.yaml` for process, syscall, network, DNS and filesystem collection.
- Recipe-defined workload commands executed by the primary agent inside the VM.
- Evidence preservation and hashing before VM destruction.

Container Use may be added for tasks that benefit from container isolation. It does not replace the Lima VM experiment boundary.

## Mandatory host stack

These components are installed and configured by `scripts/install.sh` and checked by `scripts/preflight.sh`:

| Component | Purpose |
|---|---|
| Goose | Reference primary research operator |
| Lima + QEMU | Disposable execution/isolation environment |
| Go, Node.js, npm | Reference workload tooling |
| forensic/network tools | VM instrumentation and evidence collection |
| LiteLLM + OmniRoute | Mandatory local model/provider routing |
| Numbat | Agent/process observability |
| Aegis | Independent host-level observation |
| Phoenix + OpenTelemetry | Agent telemetry/tracing |
| ClawMetry | Goose session/token visibility |

These are mandatory host capabilities. If installation or preflight cannot establish them, the host is not ready for an experiment.

## Learning workflow

Learning is **disabled by default** and starts only after the research report and independent verification are complete.

To enable learning for a session, set the session flag before continuing the primary-agent workflow:

```bash
yq -i '.learning.enabled = true' runs/<session-id>/session.yaml
```

Then tell the primary agent to continue the session with learning enabled. The primary agent follows `recipes/session/learning-workflow.yaml`:

```text
retrieve
  ↓
propose
  ↓
execute
  ↓
evaluate
  ↓
refine
  ↓
replay
  ↓
independent verification
  ↓
human approval
  ↓
promote
```

Learning artifacts are written under:

```text
runs/<session-id>/learning/
├── candidates/
├── evaluations/
├── replays/
├── verification/
└── promotions/
```

Only an approved candidate can be promoted to `skills/validated/`. Learning cannot mutate the base contract, grant privileges or weaken isolation automatically.

## Safety boundary

The contract defines authorization and research scope. The experiment recipe defines what the agent executes. The disposable Lima VM and guest OS provide the execution/isolation boundary. Instrumentation observes the VM. Gateways route model traffic. Agent/host observability records behavior. None of those observation or routing components is the workload containment boundary.

## Repository structure

```text
contracts/                         research contracts
recipes/                           authoritative experiment and environment recipes
├── go-install-001/                Go reference experiment
├── npm-install-001/               npm reference experiment
├── lima/                          disposable VM profiles
├── instrumentation/               VM instrumentation profiles
├── host/                          host tool inventory
├── gateway/                       mandatory gateway configuration
├── observability/                 mandatory observability configuration
├── session/                       session state and learning workflow
└── subrecipes/                    specialist analysis/verification/reporting
.agents/                           specialist roles and reusable Skills
scripts/
├── install.sh                    single host installation/configuration entry point
├── preflight.sh                  host readiness check
├── tools.sh                      installed-tool inventory/access helper
└── tests/                        validation and runtime integration
docs/architecture/                canonical Mermaid architecture

docs/images/                      project branding and architecture image
packages/labprobe/                 reference Go workload
runs/                              preserved per-session artifacts
```

## Validation

Static validation:

```bash
./scripts/tests/validate.sh
```

Runtime integration validation:

```bash
./scripts/tests/runtime.sh
```

A runtime PASS requires an actual disposable Lima/QEMU execution and independent verification. Configuration-only checks are not represented as runtime success.
