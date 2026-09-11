# AI Security Research Lab

A recipe-driven, fully agentic security research lab. **Goose is the project orchestrator, operator, and executor.** Markdown defines intent and security contracts; modular YAML recipes define the project; `policyctl` is the only dedicated CLI for host/security policy configuration.

## Architecture

```text
Human / CI intent
        |
        v
Markdown contracts
        |
        v
recipes/goose/project.yaml  <-- project entry recipe
        |
        v
      GOOSE
  plan / review / operate / execute / observe / investigate / verify / report
        |
        +---- modular recipes ------------------------------+
        | experiment | workload | installation | routing      |
        | host       | VM      | tools        | instrumentation |
        | monitoring | agents  | orchestration | reporting    |
        | stages     | token dashboard                       |
        +----------------------------------------------------+
        |
        +---- policyctl -> host/security policy
        |
        v
   Lima / QEMU disposable VM
        |
        v
 workload + instrumentation
        |
        v
 evidence -> deterministic reduction -> forensics -> independent verification
        |
        v
 reports / token usage / Git
```

![Project architecture](docs/images/ai-security-lab-architecture.svg)

### Design rule

> **Markdown specifies. YAML configures. Goose reasons, operates, and executes. policyctl configures policy. Evidence proves.**

There is no second project controller competing with Goose. Platform capabilities are exposed to Goose through tools/extensions and recipe-defined commands. The agent may use normal shell only for recovery/debugging when a recipe explicitly permits it.

Goose supports portable YAML recipes, including reusable subrecipes, which makes this modular composition a natural fit for the project. citeturn1search0

## Modular recipe architecture

`recipes/goose/project.yaml` is the **entry recipe**, not a giant configuration file. It composes small, independently reusable recipes:

```text
recipes/
├── goose/project.yaml             # project entry/composition recipe
├── experiments/                   # experiment compositions
├── workloads/                     # workload definitions
├── install/                       # host installation/prerequisites
├── host/                          # host profiles
├── lima/profiles/                 # VM profiles
├── tools/                         # reusable tool definitions
├── instrumentation/               # instrumentation profiles
├── agent-monitoring/              # Numbat/Phoenix/OTel profiles
├── agents/                        # agent roles
├── orchestration/                 # agent execution chains
├── routing/                       # gateway/model/harness routing
├── stages/                        # Markdown-to-recipe stage mapping
├── reporting/                     # report generation
├── token/                         # token/cost dashboard
└── tests/                         # recipe-level validation
```

A workload should normally compose existing profiles instead of creating a bespoke VM or instrumentation implementation.

## Full agentic workflow

```text
project discover
      -> project validate
      -> project preflight
      -> project plan
      -> project review / approval
      -> project bootstrap
      -> project run <experiment>
      -> collect evidence
      -> forensic analysis
      -> independent verification
      -> report + token dashboard
      -> optional Git checkpoint
```

These are **project operations implemented by the Goose workflow**, not a replacement CLI. The repository deliberately does not require a `labctl` execution layer.

## What runs where?

| Surface | Responsibility |
|---|---|
| Goose | reasoning, orchestration, operation, execution, recovery, evidence workflow, reporting |
| YAML recipes | configuration and composition |
| Markdown | requirements, threat model, research contracts |
| policyctl | host/security policy configuration only |
| Lima/QEMU | disposable workload isolation |
| Numbat/Phoenix/OTel | observation and agent telemetry |
| Git | durable configuration, manifests, reports |

The security boundary is **not Goose**. It is the combination of policy, approval, isolation, credential separation, instrumentation, evidence preservation and independent verification.

## Policy CLI

`policyctl` is deliberately separate from the agent workflow. It manages host/security policy configuration and does not orchestrate experiments.

```bash
go build ./cmd/policyctl
./policyctl show
./policyctl check
```

Privileged/destructive actions remain approval-required. Host credentials and unrestricted host mounts remain denied by default.

## Example Goose run

```text
Goose: read Markdown contracts
Goose: load recipes/goose/project.yaml
Goose: resolve experiment/go-install-001.yaml
Goose: inspect host profile + installation + VM + instrumentation + tools
Goose: preflight
Goose: produce plan
Human: approve privileged operations
Goose: provision disposable Lima VM
Goose: start instrumentation and agent monitoring
Goose: execute workload inside VM
Goose: preserve and hash evidence
Goose: reduce evidence
Goose: run forensic and independent-review agents
Goose: generate report and token dashboard
Goose: destroy VM after evidence preservation
```

No component is reported as exercised unless runtime evidence exists. Missing capabilities are recorded as `NOT_DEPLOYED`.

## Safety and authorization

Use only on systems and workloads you own or are explicitly authorized to test. Never expose host credentials to experiments, never create unrestricted host mounts, never execute unknown installers directly on the host, and preserve evidence before destroying disposable resources. See `AI-DISCLAIMER.md`, `AGENTS.md`, and `SECURITY.md`.

## Validation

Recipe validation is intentionally independent of experiment execution. CI validates YAML syntax, shell syntax and policy CLI build. Goose performs the semantic cross-reference and capability validation as part of the project workflow.

## Acceptance states

The project uses `PASS`, `PARTIAL`, `FAIL`, and `NOT_DEPLOYED`. Configuration alone is never evidence of successful execution.

## Repository layout

```text
01-11*.md       research contracts
recipes/        modular YAML source of truth
cmd/policyctl/  host/security policy configuration CLI
experiments/    historical/research artifacts
infra/          infrastructure definitions and support assets
policies/       policy configuration
reports/        generated reports
blackboard/     structured agent handoffs
antigravity/    optional harness workspace templates
```

## License

MIT. See `LICENSE` and `NOTICE`.
