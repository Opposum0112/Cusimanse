# Cusimanse

Cusimanse is a declarative security-research project. The **experiment recipe is agent-neutral**: it defines the research workflow, workload, Lima VM, instrumentation, evidence, verification and report. Goose is the reference primary operator because it provides the native recipe, planning, Skills and subagent capabilities needed by the workflow. Other primary agents can operate the same recipe through an adapter/prompt when they are actually integrated and validated.

## Researcher workflow

```text
Research question + authorization
        ↓
Contract
        ↓
Experiment recipe
        ↓
Primary agent (Goose reference)
        ↓
Native planning / Skills / specialist subagents
        ↓
Lima + QEMU disposable VM
        ↓
Instrumentation profile
        ↓
Approved workload
        ↓
Evidence
        ↓
Analysis → independent verification
        ↓
Research report
        ↓
Preserve evidence → destroy VM
```

### 1. Prepare the host

Run the single host preparation script:

```bash
./scripts/install.sh
```

It installs and configures the required researcher toolchain, Goose, Lima/QEMU, workload/forensic tools, the model gateway chain (LiteLLM → OmniRoute), and the host agent-observability stack (Numbat, Aegis, Phoenix/OpenTelemetry and ClawMetry). Provider credentials are supplied outside Git.

Check the host:

```bash
./scripts/preflight.sh
```

### 2. Validate the recipes

```bash
./scripts/tests/validate.sh
```

This checks repository cleanliness, shell syntax, YAML structure, Goose recipe validation, required Lima/instrumentation profiles and mandatory gateway/observability declarations.

### 3. Run an experiment

Goose is the reference operator:

```bash
goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive
```

or:

```bash
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
```

The primary agent must follow the recipe and contract. It must not move the workload to the host.

### 4. Go workload

Inside the disposable VM:

```bash
go version
go install ./packages/labprobe
```

### 5. npm workload

Inside the disposable VM:

```bash
node --version
npm --version
mkdir -p /tmp/npm-test
cd /tmp/npm-test
npm init -y
npm install lodash@4.17.21 --ignore-scripts
```

### 6. Inspect the result

Each run is rooted at:

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

Read, in order:

```bash
cat runs/<session-id>/research-report/report.md
cat runs/<session-id>/verification/result.md
cat runs/<session-id>/analysis/summary.md
cat runs/<session-id>/evidence/index.yaml
```

A material finding must cite observable evidence and distinguish observation, inference and independent verification. Model output is not evidence.

## Native operator model

The primary agent owns the experiment lifecycle and can delegate independent specialist work. The project keeps specialist role definitions without introducing another orchestration controller:

- planner
- researcher
- runtime analyst
- forensics analyst
- detection analyst
- verifier
- report generator

Skills are reusable instructions under `.agents/skills/`. MCP extensions and developer tools are capability providers; neither replaces the contract or the Lima execution boundary.

## Mandatory host services

These are host requirements, not optional architecture layers:

| Service | Function |
|---|---|
| Goose | Primary research operator |
| Lima + QEMU | Disposable VM execution boundary |
| LiteLLM | Local model routing |
| OmniRoute | Provider routing/fallback |
| Numbat | Agent/process observability |
| Aegis | Independent host observation |
| Phoenix + OpenTelemetry | Agent telemetry/tracing |
| ClawMetry | Agent session/token observability |

If a mandatory service cannot be installed, host preparation or preflight fails. No fake configuration is reported as deployed.

## Security boundary

The contract defines authorization and scope. The experiment recipe defines what runs. The disposable Lima VM and guest OS contain the workload. Instrumentation observes the VM; gateways route model traffic; observability services observe agents. None of those services should be treated as the workload containment boundary.

Container Use may be used as an **additional** isolated environment for suitable tasks; it does not replace the Lima experiment profile.

## Learning

After a verified experiment, a researcher may enable the learning workflow:

```text
retrieve → execute → evaluate → refine → replay → independent verification → human approval → promote
```

Promotion cannot change contracts, grant privileges or weaken isolation automatically.

## Repository layout

```text
contracts/                         research authority
recipes/
├── go-install-001/                reference Go experiment
├── npm-install-001/               reference npm experiment
├── subrecipes/                    analysis / verification / reporting
├── lima/                          disposable VM profile
├── instrumentation/               VM telemetry profile
├── host/                          host inventory
├── gateway/                       mandatory gateway declaration
└── observability/                 mandatory observability declaration
.agents/                           primary roles and Skills
scripts/
├── install.sh                    single host preparation entry point
├── preflight.sh                  host readiness check
└── tests/                        validation and integration checks
docs/architecture/                canonical architecture
packages/labprobe/                 reference Go workload
```
