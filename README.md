# AI Security Research Lab

> **An agent-neutral, modular, recipe-driven security research lab for controlled experimentation, evidence collection and independent verification.**

Markdown specifies the research contract. YAML configures reusable components. A selected agent adapter operates the workflow. Goose is the current reference adapter; Antigravity and Grok are documented alternatives. `policyctl` is the only project CLI for host/security policy decisions and the local token-usage web dashboard. Lima/QEMU provide disposable execution isolation; evidence, audit records and independent verification establish what actually happened.

## Quick start

Choose an agent adapter and run the same project contracts. The reference Goose entry recipe is:

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

The project is not Goose-dependent at the experiment-contract level. Other adapters should consume the same Markdown/YAML contracts without changing experiment semantics.

## Agent adapters

### Goose — reference adapter

`recipes/goose/project.yaml` is the maintained Goose entry recipe. Goose provides the adapter layer for planning, review, approvals, execution and evidence workflow. It does not define the security boundary.

```bash
goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project
```

### Antigravity

The `antigravity/` directory documents how Antigravity can consume the project's agent roles, skills and MCP configuration. See `antigravity/README.md` and `11-current-antigravity-reference.md`. Antigravity-specific behavior belongs in the adapter layer; experiment definitions remain provider-neutral.

### Grok

The `grok/` adapter documentation describes how a Grok-based agent can consume the same project contracts. Grok is an adapter, not a replacement project controller. Any Grok-specific integration must preserve policy, audit, evidence and verification semantics.

### Agent-neutral contract

```text
Human / CI intent
        |
        v
Markdown contracts
        |
        v
Agent adapter: Goose / Antigravity / Grok / future adapter
        |
        +---- modular recipes ------------------------------+
        | experiment | workload | installation | routing    |
        | host       | VM       | tools        | instrumentation |
        | monitoring | agents   | orchestration | reporting |
        | token dashboard | MCP | skills | audit             |
        +----------------------------------------------------+
        |
        +---- policyctl -> host/security policy
        |
        v
Disposable Lima / QEMU VM
        |
        v
Evidence -> deterministic reduction -> forensics -> independent verification
```

**Design principle:** Markdown specifies. YAML configures. Agent adapters reason/operate. `policyctl` configures policy. Audit records. Evidence proves.

## `policyctl` commands

`policyctl` is intentionally narrow: it owns **host/security policy configuration and the token-usage web dashboard only**. It is not a general project controller, experiment runner, agent harness or sandbox.

Build it with:

```bash
go build ./cmd/policyctl
```

### Show policy

```bash
./policyctl show
./policyctl show --file policies/host-policy.yaml
```

### Validate policy

```bash
./policyctl validate
./policyctl validate --file policies/host-policy.yaml
```

Validation parses the policy configuration and fails closed on invalid policy input.

### Check an action

```bash
./policyctl check --action credentials
./policyctl check --action mounts
./policyctl check --action host-root
./policyctl check --action sudo
./policyctl check --action vm
./policyctl check --action network
./policyctl check --action git-write
./policyctl check --action push
```

Add `--json` when machine-readable output is required. Policy decisions are also appended to the audit JSONL stream. Supported action names map to the corresponding policy categories; unknown actions fail rather than being implicitly allowed.

### Token-usage web dashboard

The token dashboard is also owned exclusively by `policyctl`:

```bash
./policyctl token-dashboard
```

Optional local listener configuration:

```bash
./policyctl token-dashboard --addr 127.0.0.1:8787
```

The dashboard reads `reports/token-usage/usage.json` and exposes a local HTML view plus its local usage API. It binds to localhost by default. It is an observability surface, not an authorization mechanism, and it must not be exposed publicly without an explicitly reviewed design.

## Policy decision versus enforcement

A `policyctl` result is a **policy decision/configuration result**, not a kernel or VM security boundary. A `deny` must be honored by the calling adapter. Real enforcement comes from VM isolation, OS permissions, mount controls, credential separation, network controls and approval workflows. Prompts, skills, MCP servers and policy output must never be treated as the sole security boundary.

The default policy includes:

- host credentials: deny;
- unrestricted host mounts: deny;
- untrusted host execution: deny;
- privileged defaults: approval-required;
- disposable VM: approval-required;
- Lima/QEMU: explicitly allowed as virtualization mechanisms;
- public MCP/gateway exposure: deny;
- Git writes/pushes: approval-required;
- evidence preservation and hashing: required.

## Modular recipe families

```text
recipes/
├── experiments/        # experiment compositions
├── workloads/          # workload definitions
├── install/            # prerequisites and installation
├── host/               # host profiles
├── lima/profiles/      # VM profiles
├── tools/              # tool inventory
├── instrumentation/    # instrumentation profiles
├── agent-monitoring/   # agent/trace observation
├── agents/             # provider-neutral agent roles
├── orchestration/      # workflow composition
├── routing/            # model/harness routing
├── stages/             # execution stages
├── reporting/          # report recipes
├── token/              # token telemetry configuration
├── mcp/                # MCP registry
├── skills/             # skill registry
├── audit/              # audit layer
├── tests/              # recipe validation
└── goose/              # Goose reference adapter entry recipe
```

An experiment selects reusable profiles rather than duplicating VM, workload or instrumentation configuration without a genuine capability difference.

## Execution lifecycle

The reference workflow is:

```text
discover -> validate -> preflight -> install -> plan -> review -> approve
-> provision -> instrument -> execute -> collect -> reduce -> forensics
-> independent verification -> report -> preserve evidence -> destroy
```

Runtime `PASS` requires evidence. Configuration alone is never proof. If a capability is unavailable, record `NOT_DEPLOYED` rather than silently substituting a weaker implementation.

## MCP, skills and audit

- `recipes/mcp/registry.yaml` declares MCP capabilities and exposure rules.
- `recipes/skills/registry.yaml` declares reviewed reusable agent instructions.
- `recipes/audit/default.yaml` defines append-only audit records.
- `.agents/` contains provider-neutral project roles, skills and MCP configuration.

Skills are instructions, not security boundaries. They cannot grant privileges. MCP arguments must not carry secrets. Audit records distinguish requested, approved, executed and observed actions and avoid storing raw credentials.

## Installation and prerequisites

The repository contains reusable installation recipes. The convenience script is currently Goose-specific because Goose is the reference adapter:

```bash
./scripts/install.sh
```

For another adapter, consume `recipes/install/project-bootstrap.yaml` through that adapter instead of introducing a second project controller.

Required host capabilities depend on the selected experiment and profile, typically including Git, Bash, Lima and QEMU. VM tools are declared by the tools recipe. Optional observability tools are capability-gated.

## The `scripts/` directory and retired `labctl`

The repository previously contained a Python `labctl` project controller under `scripts/`. That architecture has been **retired** because it duplicated orchestration responsibilities and conflicted with the agent-neutral design.

The current `scripts/` directory is intentionally limited to supporting shell utilities, installation convenience and validation. **Do not recreate or depend on `./scripts/bin/labctl` or `scripts/labctl/`.**

The repository was checked for `labctl` references during this refactor. The old controller code is removed; the validation suite explicitly fails if the retired controller paths reappear.

## Validation before merge

Run the project validation from the repository root:

```bash
bash ./scripts/tests/validate-project.sh
```

The validation script:

1. parses every recipe YAML file;
2. syntax-checks shell scripts;
3. verifies the retired `labctl` controller is absent;
4. verifies required policy and `policyctl` sources exist;
5. checks Go formatting;
6. runs Go unit tests;
7. builds `policyctl`;
8. validates the host policy;
9. exercises representative policy decisions and audit output;
10. runs Python unit tests when Python is available.

For recipe-only validation:

```bash
bash ./scripts/tests/validate-recipes.sh
```

For the Python test suite:

```bash
PYTHONPATH=scripts python3 -m unittest discover -s scripts/tests -v
```

For Go tests:

```bash
go test ./...
```

The GitHub Actions validation workflow runs the same project validation before a pull request can be considered ready.

## AI disclaimer

This project uses AI agents as research assistants and workflow operators. AI output can be incomplete, incorrect, stale, overconfident or unsafe. Generated plans, explanations, commands and findings are **not evidence by themselves** and must not be treated as authoritative security conclusions.

Use deterministic tooling, captured telemetry, hashes, manifests and independent verification to establish facts. Human researchers remain responsible for authorization, scope, approvals and final interpretation. Never provide an AI agent with credentials or host access merely because a prompt requests it.

A successful agent response does not imply that an experiment succeeded. Conversely, an agent failure does not prove that the underlying system is safe. Record uncertainty explicitly.

## Security model

Use the lab only against systems, software and workloads you own or are explicitly authorized to test.

Core controls:

- execute untrusted workloads inside disposable VMs;
- deny host credential exposure;
- deny unrestricted host filesystem mounts;
- require approval for privileged or destructive actions;
- start instrumentation before workload execution;
- preserve and hash evidence before destroying a VM;
- reduce large raw evidence deterministically before sending it to an LLM where practical;
- independently verify important findings;
- bind local services to localhost by default;
- treat missing controls as `NOT_DEPLOYED`, not as success.

The VM boundary and operating-system controls provide isolation. `policyctl` provides policy decisions. The agent adapter is responsible for honoring those decisions. No single AI component is trusted as the security boundary.

See `SECURITY.md` and `AI-DISCLAIMER.md` for the fuller security and AI guidance.

## Contribution guidelines

Contributions should preserve the architecture rather than introduce parallel control planes.

1. Read `AGENTS.md` and the relevant Markdown contract before changing behavior.
2. Prefer a reusable Markdown contract and YAML recipe over hard-coded agent-specific logic.
3. Keep experiment semantics independent of the selected agent adapter.
4. Keep `policyctl` limited to host/security policy and token dashboard responsibilities.
5. Do not introduce or revive a project controller such as the retired `labctl`.
6. Never commit credentials, tokens, private keys, raw sensitive telemetry or unrestricted host mounts.
7. Add or update tests when behavior changes.
8. Run the validation suite before opening a pull request.
9. Document platform-specific limitations and mark unavailable capabilities `NOT_DEPLOYED`.
10. For security-sensitive changes, explain the threat model, enforcement point and evidence required to demonstrate the control.

Pull requests should describe the architectural impact, affected recipes, adapter compatibility, validation performed and any remaining limitations.

## Documentation map

| Document | Purpose |
|---|---|
| `01-deployment-architecture.md` | system boundaries and components |
| `02-system-requirements.md` | host and VM prerequisites |
| `03-deployment-runbook.md` | installation and first run |
| `04-security-model.md` | threats and security controls |
| `05-multi-agent-operating-model.md` | roles and handoffs |
| `06-observability-and-evidence.md` | telemetry and evidence |
| `07-experiment-framework.md` | reusable experiment design |
| `08-go-install-001.md` | end-to-end acceptance experiment |
| `09-operations-and-maintenance.md` | upgrades and recovery |
| `10-validation-and-acceptance.md` | acceptance semantics |
| `11-current-antigravity-reference.md` | Antigravity adapter reference |
| `AI-DISCLAIMER.md` | AI limitations and responsibility |
| `CONTRIBUTING.md` | contribution process |
| `SECURITY.md` | security reporting and policy |

## Acceptance semantics

| State | Meaning |
|---|---|
| `PASS` | required runtime behavior was demonstrated with evidence |
| `PARTIAL` | some required capability worked, but coverage or evidence is incomplete |
| `FAIL` | required behavior was tested and did not meet the contract |
| `NOT_DEPLOYED` | required capability was unavailable or intentionally not enabled |

**Configuration is not evidence. AI assertions are not evidence. Runtime artifacts, deterministic measurements and independent verification are evidence.**

## License

MIT. See `LICENSE` and `NOTICE`.
