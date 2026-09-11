# AI Security Research Lab — Full Agentic SecOps Workload Research Platform

A workload-neutral, recipe-driven security research platform in which **Goose is the project operator**. Goose reads the Markdown research contracts and YAML recipe graph, coordinates specialized agents, invokes the deterministic Go control plane, runs research workloads in disposable Lima/QEMU environments, collects evidence, performs forensic and independent review, generates reports and token-usage dashboards, and commits approved artifacts.

## Platform model

```text
Human intent / approval
          ↓
        Goose
          ↓
Markdown contracts + YAML recipes
          ↓
Multi-agent orchestration
          ↓
Harness Router → LLM Gateway / OmniRoute
          ↓
Go deterministic control plane
          ↓
Policy + capability + approval checks
          ↓
Disposable Lima/QEMU VM
          ↓
Workload + instrumentation
          ↓
Host agent monitoring + VM telemetry
          ↓
Evidence preservation + deterministic reduction
          ↓
Forensic review + independent verification
          ↓
Report + token/cost dashboard
          ↓
Approved Git commit
```

**Goose reasons and orchestrates. Go executes deterministic operations. YAML customizes behaviour. Markdown defines research intent and operational contracts. Evidence, policy, isolation and approval—not the LLM—form the security boundary.**

## What runs where?

### Goose — project operator

Goose is the normal operating interface for the platform. It reads the applicable Markdown contracts and **all relevant YAML recipes**, resolves the project graph, delegates work to the configured planner/reviewer/executor/forensic/reporting agents, invokes the Go control plane, and returns durable reports and evidence manifests.

Goose is responsible for reasoning, planning, delegation, context selection, model routing requests, forensic interpretation and report composition. It must not invent execution semantics or bypass the deterministic control plane.

### Go control plane / `labctl` — deterministic execution substrate

The Go control plane is responsible for recipe loading and validation, host capability detection, prerequisite installation, policy enforcement, approval boundaries, VM lifecycle, instrumentation, evidence preservation/reduction, monitoring integration, artifact generation and other deterministic operations.

`labctl` is the CLI façade over that Go execution layer. It is **not a competing agent interface**. Goose invokes the same deterministic control-plane capabilities through the configured integration. `scripts/bin/labctl` remains a compatibility entry point while the Python implementation is migrated to Go.

### Host

The host provides the minimum substrate required by the selected recipes: operating-system facilities, virtualization, Lima/QEMU or another explicitly supported backend, networking, agent telemetry and evidence storage. Host credentials and unrestricted mounts are denied by policy.

### Disposable VM

Untrusted package installation and workload execution happen inside the selected disposable VM. The VM profile, network policy, instrumentation and workload are selected from YAML recipes.

### LLM Gateway / OmniRoute

The routing layer selects models for the different agent roles and provides context/token optimisation and telemetry. Raw evidence is not blindly sent to models; deterministic reductions are preferred.

### Numbat / Phoenix / OpenTelemetry

Host-side and agent-side telemetry observes the operator and research process. These systems provide observability, not authorization to bypass the Go control plane.

### Evidence / Git

Evidence is preserved and hashed before disposable resources are destroyed. Forensic findings, verification results, reports, manifests and token dashboards are generated as durable artifacts. Goose may commit only artifacts explicitly permitted by the active recipe and after required review.

## Fully recipe-driven platform

The primary customization surface is `recipes/`:

```text
recipes/
├── stages/                 # Markdown → stage execution contracts
├── workloads/              # workload definitions
├── lima/profiles/          # disposable VM infrastructure
├── instrumentation/        # syscall/network/filesystem/eBPF collectors
├── host/                   # host capabilities and tools
├── agent-monitoring/       # Numbat/Phoenix/OpenTelemetry settings
├── agents/                 # reusable agent roles
├── orchestration/          # multi-agent stage chains
├── gateway/                # gateway and harness-router configuration
├── install/                # bootstrap/prerequisite recipes
├── tests/                  # validation recipes
└── goose/                  # Goose project/operator/reporting recipes
```

A new workload should normally be created by composing existing VM, instrumentation, monitoring, orchestration and routing recipes. Do not create a bespoke VM implementation unless the workload genuinely requires one.

## Bootstrap once; operate entirely through recipes

Installation is itself recipe-driven. The intended lifecycle is:

```text
Bootstrap Goose + minimal launcher
          ↓
Goose reads installation recipe
          ↓
Detect host capabilities
          ↓
Install declared prerequisites
          ↓
Validate complete recipe graph
          ↓
Platform ready
          ↓
All subsequent operation through Goose recipes
```

The installation recipe is `recipes/install/install-all.yaml`. Platform-specific package managers remain implementation details of the deterministic Go control plane. Unsupported capabilities must be reported as `NOT_DEPLOYED`; they must never be silently bypassed.

The normal host shell is retained for recovery, debugging, development and emergency bootstrap only. It is not the normal project operating workflow.

## Goose implementation contract

The canonical project-level Goose instruction is:

`recipes/goose/implementation-prompt.yaml`

It directs Goose to read the Markdown and YAML source of truth, validate dependencies, resolve prerequisites, plan, review, request approval, execute through the Go control plane, preserve evidence, perform forensic and independent review, generate reports/dashboards and commit permitted artifacts. It explicitly forbids host credentials, unrestricted mounts, direct host execution of untrusted workloads and control-plane bypass.

## Goose operating commands

The exact command syntax is supplied by the active Goose harness and must not be invented by an agent. Conceptually, Goose should expose project operations corresponding to:

```text
project discover       # read Markdown + YAML
project validate       # validate recipe graph
project preflight      # detect host capabilities
project bootstrap      # execute installation recipe
project plan           # construct execution plan
project review         # invoke reviewer/approval stage
project run <recipe>   # execute approved workload/stage
project collect        # preserve evidence
project forensic       # forensic review
project verify         # independent verification
project report         # generate reports
project tokens         # generate token/cost dashboard
project commit         # commit recipe-permitted artifacts
```

These are **Goose-level operations**, not promises that the underlying CLI has identically named subcommands. Goose must resolve them to capabilities provided by the Go control plane and active recipes.

For implementation tasks, use the project prompt recipe and follow this sequence:

```text
read contracts → validate recipes → preflight → bootstrap if needed
→ plan → review → approval → execute → collect → reduce
→ forensic review → independent verification → report → dashboard → commit
```

## Go control plane and portability

The project is designed to converge on a portable Go execution package:

```text
Go package
    ↓
recipe engine
capability engine
policy engine
execution engine
VM backends
instrumentation
monitoring
evidence
reporting
Git/artifact management
    ↓
`labctl` CLI
    ↓
Goose
```

The Go layer should keep platform-specific operations behind interfaces such as VM backend, instrumentation collector, monitoring backend and package installer. Capability detection determines whether a selected backend can actually run.

This allows the same recipe graph to be reused across supported platforms without embedding Linux- or Lima-specific assumptions in the agent layer.

The current migration is incremental: the existing Python controller remains a compatibility implementation while deterministic functionality is moved into Go. Go parity and runtime validation are required before retiring the Python path.

See `recipes/goose/go-control-plane.yaml` for the target architecture.

## Research lifecycle

```text
Markdown research contract
        ↓
YAML workload recipe
        ↓
VM + instrumentation + monitoring resolution
        ↓
Agent plan/review
        ↓
Disposable execution
        ↓
Evidence preservation
        ↓
Deterministic reduction
        ↓
Forensic analysis
        ↓
Independent verification
        ↓
SecOps / experiment report
        ↓
Token/cost dashboard
        ↓
Git artifact commit
```

The forensic process must distinguish observations, derived indicators, hypotheses and independently verified conclusions. LLM summaries are never substitutes for raw evidence.

## Safety boundary

This platform is for systems and workloads you own or are explicitly authorised to test.

- Untrusted workloads run in disposable VMs.
- Host credentials are never forwarded to workloads.
- Unrestricted host mounts are denied.
- Mutating execution requires the configured approval boundary.
- Evidence is preserved before VM destruction.
- Agent output is treated as untrusted until verified.
- Unsupported capabilities are reported as `NOT_DEPLOYED`.
- No component is marked `PASS` merely because its configuration exists.

See `AI-DISCLAIMER.md`, `AGENTS.md`, `SECURITY.md` and `CONTRIBUTING.md`.

## Architecture

![AI Security Lab — Project Architecture](docs/images/ai-security-lab-architecture.svg)

The architecture separates intelligent orchestration from deterministic execution while keeping the entire research lifecycle recipe-driven.

## Acceptance

The platform uses `PASS`, `PARTIAL`, `FAIL` and `NOT_DEPLOYED`. Runtime evidence is required before claiming that a backend, agent, instrument, workload or observability component has actually been exercised.

## Repository layout

```text
01-*.md              research contracts and operational documentation
recipes/              YAML source of truth
recipes/goose/        Goose operator/execution/reporting recipes
cmd/labctl/           Go control-plane migration
scripts/labctl/       Python compatibility control plane
scripts/              bootstrap/validation/recovery helpers
experiments/           reproducible experiment contracts
infra/                 generated infrastructure
policies/              permission/mount controls
evidence/              runtime evidence (normally gitignored)
reports/               reports and acceptance artifacts
```

## License

MIT. See `LICENSE` and `NOTICE`.
