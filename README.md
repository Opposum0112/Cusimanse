# AI Security Research Lab — Full Agentic SecOps Workload Research Platform

A workload-neutral, recipe-driven security research platform for studying how software workloads behave inside disposable Lima/QEMU VMs, while AI agents automate the complete research lifecycle and host-side tooling observes agent behaviour.

## What this project is

The lab combines **SecOps automation, workload security research, VM isolation, instrumentation, AI-agent orchestration, evidence collection, forensic review, reporting and token observability**.

The core idea is simple:

```text
Markdown research contracts
        ↓
Customisable YAML recipes
        ↓
Goose multi-agent execution layer
        ↓
LLM Gateway / OmniRoute + Harness Router
        ↓
Host preflight + prerequisites
        ↓
Lima/QEMU disposable VM
        ↓
Selected workload + instrumentation
        ↓
Host agent monitoring + VM telemetry
        ↓
Evidence preservation
        ↓
Forensic + independent review
        ↓
AI-assisted report generation
        ↓
Token/cost dashboard
```

**Recipes are the configuration layer. Goose is the agentic execution layer. `labctl` and repository policy remain the execution/security boundary.**

## Fully recipe-driven customization

All important project behaviour is intended to be expressed in YAML:

```text
recipes/
├── stages/                 # Markdown → stage execution contracts
├── workloads/              # npm, Go and future pip/cargo/build workloads
├── lima/profiles/          # disposable VM infrastructure profiles
├── instrumentation/        # syscall/network/filesystem/eBPF collectors
├── host/                   # host tools and agent observation surfaces
├── agent-monitoring/       # Numbat/Phoenix/OpenTelemetry settings
├── agents/                 # reusable agent role definitions
├── orchestration/          # multi-agent stage chains
├── gateway/                # LLM gateway + harness-router settings
├── install/                # host prerequisite recipes
├── tests/                  # recipe validation recipes
└── goose/                  # Goose project/execution/report/token recipes
```

To create a new experiment, normally change a workload YAML and select existing VM, instrumentation, monitoring and orchestration recipes. A new VM implementation should not be required for each workload.

## Goose as the project operator

The intended agent-driven workflow is defined in `recipes/goose/`.

1. Goose reads the Markdown contracts and YAML recipe set.
2. The **planner** builds the execution plan.
3. The **reviewer** checks prerequisites, safety, profile compatibility and evidence requirements.
4. The **executor** invokes approved `labctl` and shell automation and runs workload actions inside the disposable VM.
5. The **forensic reviewer** analyzes preserved evidence.
6. The **independent reviewer** challenges findings and separates observation from inference.
7. The **report generator** creates the experiment/SecOps report.
8. The token dashboard generator summarizes model usage, latency, retries, cache hits and estimated cost.

This makes Goose the project-level automation layer without making the LLM the security boundary.

See `recipes/goose/README.md` and `recipes/goose/project.yaml`.

## LLM gateway, OmniRoute and harness routing

The routing layer is deliberately configurable. Gateway and harness-router YAML recipes select models, roles, routing policy and telemetry settings. This permits the same experiment to use different models or gateways without rewriting the workload.

Use the gateway for **context/token optimisation and model routing**, while keeping raw evidence outside the LLM context. Deterministic reductions should be passed to agents whenever possible.

## What runs where?

**Normal host shell:** installation, preflight, recipe validation and `labctl` run from the normal shell.

**Goose/AI agent:** Goose reads recipes and coordinates the stages. Antigravity, OpenCode, Codex or another approved harness can be used as an entry point where configured by the harness-router recipe.

**Disposable VM:** untrusted workload installation and workload execution happen inside the selected VM. Host credentials and unrestricted host mounts are denied by default.

`--apply` is the explicit execution boundary. An agent must not be granted unrestricted host access merely because it can execute shell commands.

## Install once, then operate by recipes

```bash
./scripts/install.sh
./scripts/bin/labctl preflight
./scripts/tests/validate-recipes.sh
./scripts/bin/labctl init --dry-run
```

Review the plan and platform capability result before applying changes. Third-party tools remain optional and platform-dependent; unsupported capabilities must be reported rather than silently bypassed.

## Run a workload

Select:

```text
workload → Lima profile → instrumentation → agent monitoring → orchestration → gateway/router
```

For example, `recipes/workloads/npm-install-001.yaml` can be customised for a pinned npm package while reusing the same VM and instrumentation profiles.

The lifecycle is:

```text
plan → review → preflight → prepare → instrument → execute → preserve → forensic review → independent verification → report
```

## Evidence and forensic analysis

Evidence is preserved before disposable resources are destroyed. Typical streams include process activity, syscalls, network packets, DNS, filesystem changes, hashes and AI-agent telemetry.

The forensic recipe must distinguish:

- observed facts;
- derived indicators;
- hypotheses;
- conclusions requiring independent verification.

Raw evidence remains the durable source. LLM summaries are not substitutes for evidence.

## Token usage and optimisation

`recipes/goose/token-dashboard.yaml` defines the token dashboard contract. It can aggregate usage by run, stage, agent and model and report tokens, latency, retries, cache hits and estimated cost.

The optimisation policy favours deterministic reduction, reusable/cached context and routing simple tasks to lower-cost models where the configured gateway supports it.

## Safety

This is a security-research framework for systems you own or are explicitly authorised to test. Use disposable VMs for untrusted workloads, never forward host credentials, avoid unrestricted mounts, preserve evidence before destruction and require review before mutating operations.

The AI agent, LLM gateway and harness are **not** the security boundary. Isolation, policy, explicit approval, evidence handling and independent verification are.

See `AI-DISCLAIMER.md`, `AGENTS.md`, `SECURITY.md` and `CONTRIBUTING.md`.

## Architecture

![AI Security Lab — Project Architecture](docs/images/ai-security-lab-architecture.svg)

The platform separates workload definitions, Lima infrastructure, instrumentation, host monitoring, agent orchestration, model routing, evidence and reporting so the same execution framework can research many workloads.

## Portability and acceptance

Lima/QEMU support is strongest on validated Linux x86_64 configurations. Other OS/architecture combinations must be validated before being reported as supported.

The project uses `PASS`, `PARTIAL`, `FAIL` and `NOT_DEPLOYED`. Configuration existing on disk is not evidence that a component works. Runtime integration must be exercised on the target host.

## Repository layout

```text
01-*.md              research contracts and operational documentation
recipes/              YAML source of truth
recipes/goose/        Goose agentic execution/reporting recipes
scripts/              installation, validation and shell automation
scripts/labctl/       current Python control plane
cmd/labctl/           Go control-plane migration
experiments/           reproducible experiment contracts
infra/                 generated infrastructure
policies/              permission/mount controls
evidence/              runtime evidence (normally gitignored)
reports/               reports and acceptance artifacts
```

## License

MIT. See `LICENSE` and `NOTICE`.
