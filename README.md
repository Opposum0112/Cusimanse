# Cusimanse

![Cusimanse mascot and logo](docs/images/cusimanse-mascot-logo.svg)

**Declarative, agent-neutral security research with AI agents.** A YAML experiment recipe is the source of truth for the contract, Lima VM, instrumentation, workload, evidence, verification, report and learning settings. **Goose is the reference primary operator**; other validated primary agents can use the same recipe through their adapter/prompt path.

![Cusimanse architecture](docs/images/cusimanse-architecture.svg)

## Researcher workflow

### 1. Prepare the host once

From the repository root:

```bash
./scripts/install.sh
./scripts/preflight.sh
```

`install.sh` is the single host preparation entry point. It installs the declared host stack, including Goose, Lima/QEMU, workload and forensic tools, mandatory gateways, mandatory agent/host observability and their local configuration.

The authoritative host inventory is:

```text
recipes/host/security-research.yaml
```

The YAML recipe declares the inventory and configuration locations; `scripts/install.sh` implements that declaration. Do not maintain a second host-tool inventory.

Load the configured environment when needed:

```bash
source ~/.config/cusimanse/goose.env
source ~/.config/cusimanse/observability.env
source ~/.config/cusimanse/omniroute.env
```

### 2. Validate the repository and host

```bash
./scripts/tests/validate.sh
./scripts/preflight.sh
```

A required capability that cannot be installed or verified makes the host not ready for a reference experiment.

### 3. Start the primary agent manually

The researcher chooses the contract and experiment recipe, then starts the selected primary agent. Goose is the reference example:

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
```

For npm:

```bash
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
```

The researcher can also start another validated primary agent using its adapter/prompt handoff. The experiment recipe remains unchanged.

### 4. Let the recipe and agent run the workload

**Do not copy workload commands from the README and run them on the host.** The experiment recipe defines the workload and the primary agent executes it inside the disposable Lima VM after provisioning and instrumentation.

For the Go experiment, the recipe contains:

```text
go version
go install ./packages/labprobe
```

For the npm experiment, the recipe contains:

```text
node --version
npm --version
mkdir -p /tmp/npm-test
cd /tmp/npm-test
npm init -y
npm install lodash@4.17.21 --ignore-scripts
```

The agent performs the VM creation, instrumentation startup, workload execution, evidence collection, analysis delegation, verification and report generation according to the recipe.

### 5. Review the completed experiment

When the agent finishes, inspect the session directory:

```bash
ls -la runs/<session-id>/
cat runs/<session-id>/research-report/report.md
cat runs/<session-id>/verification/result.md
cat runs/<session-id>/analysis/summary.md
cat runs/<session-id>/evidence/index.yaml
cat runs/<session-id>/session.yaml
```

The researcher-facing primary output is `research-report/report.md`, backed by the preserved evidence and verification records.

## Recipe and agent model

```text
Researcher
   ↓
Contract (intent, scope, safety, acceptance)
   ↓
Agent-neutral YAML experiment recipe (source of truth)
   ↓
Primary agent
   ├── Goose: reference native operator
   └── Other validated agents: adapter/prompt handoff
          ↓
   Native planning / multiagent delegation / Skills / MCP
          ↓
   Lima + QEMU disposable VM
          ↓
   Instrumentation profile
          ↓
   Recipe-defined workload
          ↓
   Evidence + session.yaml
          ↓
   Specialist analysis → independent verification
          ↓
   Research report
          ↓
   Preserve → destroy VM
          ↓
   Optional learning after verification + approval
```

Specialist role definitions remain under `.agents/agents/`. The primary agent can delegate those roles using native subagents/subrecipes; a separate orchestration controller is not required.

## Host tools: configuration and access

Host tools are **declared in YAML recipes**, not configured by editing shell commands in normal use.

Authoritative inventory:

```text
recipes/host/security-research.yaml
```

Install/configure the declared stack:

```bash
./scripts/install.sh
```

Check readiness:

```bash
./scripts/preflight.sh
```

List every declared host capability and whether it is installed:

```bash
./scripts/tools.sh list
```

Show installed versions:

```bash
./scripts/tools.sh versions
```

Show non-secret configuration locations:

```bash
./scripts/tools.sh config
```

After installation, installed command-line tools are accessed normally from the shell. For example:

```bash
go version
node --version
npm --version
limactl --version
qemu-system-x86_64 --version
goose --version
litellm --version
omniroute --version
numbat --help
git --version
jq --version
yq --version
rg --version
strace --version
tcpdump --version
lsof -v
```

To locate any installed executable:

```bash
command -v <tool>
```

To see the complete configured PATH:

```bash
echo "$PATH" | tr ':' '\n'
```

Cusimanse adds `~/.local/bin` and `~/go/bin` to the PATH. The Python observability/gateway environment is kept in `~/.local/share/cusimanse/venv/`.

## Mandatory host stack

The following capabilities are mandatory host preparation for the reference project:

| Capability | Purpose | Access |
|---|---|---|
| Goose | Reference primary agent | `goose --help` |
| Lima + QEMU | Disposable VM execution | `limactl`, `qemu-system-x86_64` |
| Go / Node.js / npm | Reference workloads | `go`, `node`, `npm` |
| Forensic/network utilities | VM instrumentation and evidence | `ps`, `ss`, `ip`, `dig`, `lsof`, `strace`, `tcpdump`, etc. |
| LiteLLM | Model gateway | `litellm` |
| OmniRoute | Provider routing/fallback | `omniroute` |
| Numbat | Agent/process observability | `numbat` |
| Aegis | Host-level observation | `cusimanse-aegis` |
| Phoenix/OpenTelemetry | Agent telemetry/tracing | Python environment / OTEL configuration |
| ClawMetry | Goose session/token visibility | `clawmetry` |

Gateway and observability components are **mandatory host capabilities**, not optional experiment layers. Their configuration is created by `scripts/install.sh` from the repository's YAML declarations and local environment files.

## Execution and instrumentation

Every reference experiment uses:

- `recipes/lima/security-research.yaml` for the disposable Lima/QEMU VM.
- `recipes/instrumentation/security-research.yaml` for process, syscall, network, DNS and filesystem collection.
- Recipe-defined workload commands executed by the primary agent inside the VM.
- Evidence preservation and hashing before VM destruction.

Container Use is optional. It can provide an additional containerized environment for tasks that benefit from it, but it does not replace the Lima VM experiment boundary.

## Session state and artifacts

Keep `recipes/session/session-state.yaml` as the canonical session-state contract. Every experiment creates:

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

`session.yaml` records immutable experiment identity, selected profiles, lifecycle checkpoints, approvals, audit state, evidence, verification, reporting and learning state. The researcher should read the report first and use the remaining artifacts to substantiate its claims.

## Learning workflow — explicitly opt in

Learning is **off by default**. It never starts merely because an experiment completed.

### Enable learning for a run

1. Run the normal experiment and wait until the report and independent verification are complete.
2. Set the session flag in the generated `runs/<session-id>/session.yaml`:

```bash
yq -i '.learning.enabled = true' runs/<session-id>/session.yaml
```

3. Confirm it:

```bash
yq '.learning.enabled' runs/<session-id>/session.yaml
```

It must print:

```text
true
```

4. Manually tell the primary agent to continue the completed session with learning enabled and use:

```text
recipes/session/learning-workflow.yaml
```

The primary agent then performs:

```text
retrieve → propose → execute → evaluate → refine → replay
→ independent verification → human approval → promote
```

5. Review candidates before approval:

```bash
find runs/<session-id>/learning -type f -maxdepth 3 -print
```

6. Only after explicit researcher approval may a candidate be promoted to:

```text
skills/validated/
```

Learning artifacts remain under `runs/<session-id>/learning/`. Learning cannot mutate base contracts, grant privileges or weaken execution controls automatically.

## Validation and runtime integration

Static/project validation:

```bash
./scripts/tests/validate.sh
```

Runtime integration test:

```bash
./scripts/tests/runtime.sh
```

For a real disposable-VM runtime test:

```bash
CUSIMANSE_RUN_VM_TEST=1 ./scripts/tests/runtime.sh
```

A runtime PASS requires actual Lima/QEMU execution and independent verification. Static configuration success is not runtime success.

## Repository structure

```text
contracts/                         research intent, scope and acceptance
recipes/                           authoritative YAML configuration
├── go-install-001/                Go experiment
├── npm-install-001/               npm experiment
├── lima/                          Lima/QEMU profiles
├── instrumentation/               instrumentation profiles
├── host/                          mandatory host inventory
├── gateway/                       mandatory gateway configuration
├── observability/                 mandatory observability configuration
├── session/                       session state and learning workflow
└── subrecipes/                    specialist analysis/verification/reporting
.agents/
├── agents/                        specialist role definitions
└── skills/                        reusable agent Skills
scripts/
├── install.sh                     unified host installation/configuration
├── preflight.sh                   host readiness
├── tools.sh                       host-tool inventory/access
└── tests/                         validation and runtime integration
docs/architecture/                canonical SVG + Mermaid architecture
docs/images/                      mascot/logo and architecture artwork
packages/labprobe/                 reference Go workload
runs/                              per-session evidence and reports
```

## Safety boundary

The contract defines authorization and research scope. The recipe defines the experiment. The primary agent operates it. Lima/QEMU plus the guest OS provide the execution/isolation boundary. Instrumentation observes the VM. Gateways route model/provider traffic. Observability records behavior. None of the routing or observation components is the workload containment boundary.
