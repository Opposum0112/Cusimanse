# AI Security Research Lab

> **An agent-neutral, modular, recipe-driven AI-assisted security research lab for controlled experimentation, evidence collection and independent verification.**

This project **uses AI agents** as research assistants and workflow operators for planning, recipe interpretation, tool coordination, evidence reduction, forensics assistance and reporting. AI output is fallible and is never treated as evidence or as the security boundary. Runtime artifacts, deterministic measurements and independent verification establish what actually happened.

Markdown specifies the research contract. YAML configures reusable components. An agent adapter operates the workflow. Goose is the current reference adapter; OpenCode, Grok Build and Antigravity are documented adapter targets. `policyctl` is the only project CLI for host/security policy and the local token dashboard. Lima/QEMU provide disposable execution isolation.

![Project architecture](docs/images/ai-security-lab-project-architecture.svg)

## Architecture

```text
Human / CI intent
      ↓
Markdown experiment contract
      ↓
Goose project recipe
      ↓
┌──────────────────────────────────────────────┐
│ Agent adapter: Goose / OpenCode / Grok Build │
│                 / Antigravity / future       │
└──────────────────┬───────────────────────────┘
                   ↓
       recipes + MCP + skills + policyctl
                   ↓
          plan → review → approval
                   ↓
             Lima / QEMU VM
                   ↓
      instrument → execute → collect
                   ↓
 blackboard + evidence → reduce → forensics
                   ↓
 verify → report → preserve → destroy
```

**Boundary rule:** an adapter may change how an agent operates tools, but must not change experiment semantics, bypass policy, suppress audit, expose credentials, or claim `PASS` without evidence.

## Deploy and run

### 1. Install prerequisites

From the repository root:

```bash
./scripts/prerequisites.sh
```

The script detects OS, Linux distribution and CPU architecture; checks required tools; installs only missing prerequisites using the supported package manager; configures `~/.local/bin`; and re-checks the result. It is intended to be **idempotent**.

Successful setup ends with:

```text
OS PASS: ...
Tools PASS: git bash python3 qemu-system-x86_64 limactl goose
Prerequisite PASS
```

### 2. Load the project environment

```bash
source ./scripts/goose-env.sh
```

This only sets project paths and user-local executable lookup. **Never put API keys, cloud credentials or secrets in it.** Keep provider credentials in Goose's supported configuration outside the repository.

### 3. Verify Goose and the project

```bash
command -v goose
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

If the validator reports `PASS project validation`, continue with the operator workflow.

### 4. Run the Goose installation/bootstrap recipe

For a clean machine or first project deployment:

```bash
goose run --recipe recipes/install/project-bootstrap.yaml
```

This installs/configures only capabilities declared by the project installation recipe. Review any approval-required action rather than bypassing policy.

### 5. Run the project recipe

The Goose project recipe is the reference end-to-end operator workflow. Start with the reference experiment:

```bash
goose run \
  --recipe recipes/goose/project.yaml \
  --params experiment=go-install-001 \
  --params section=project
```

The recipe drives the complete lifecycle:

```text
Discover → Validate → Preflight → Install → Plan → Review → Approve
    → Provision → Instrument → Execute → Collect → Reduce → Forensics
    → Independent verification → Report → Preserve → Destroy
```

If you want to execute a narrower section while developing a recipe, use the appropriate section/parameters defined by the recipe rather than inventing an alternative project controller.

### 6. Operator checkpoints

The Goose operator should stop and obtain the required approval whenever the recipe/policy marks an operation as approval-required. In particular:

1. **Preflight:** confirm host tools, Lima/QEMU, recipe inputs and policy state.
2. **Plan/review:** inspect the proposed workload, mounts, network, privileges and evidence plan.
3. **Approval:** explicitly approve privileged, destructive or VM-provisioning actions when required.
4. **Provision:** create the disposable Lima/QEMU VM; do not expose host credentials or unrestricted host mounts.
5. **Instrument:** start required telemetry **before** the target workload.
6. **Execute:** run only the approved workload and declared tools.
7. **Collect:** capture runtime evidence, telemetry, audit and blackboard handoffs.
8. **Reduce:** deterministically reduce large evidence before sending it to an LLM where practical.
9. **Forensics:** analyse preserved artifacts and record uncertainty.
10. **Verify:** independently reproduce or test important findings; an AI assertion is not proof.
11. **Report/preserve:** generate the report and manifest, hash important evidence and preserve it.
12. **Destroy:** remove the disposable VM only after required evidence has been preserved.

### 7. Inspect outputs

A run should produce durable artifacts such as:

```text
runs/<run-id>/
├── blackboard/
├── evidence/
├── telemetry/
├── audit/
├── reductions/
├── forensics/
├── verification/
├── reports/
└── manifest.json
```

Repository-level policy audit data is under `evidence/audit/`; token usage is under `reports/token-usage/`. Monitoring outputs from deployed Numbat/Phoenix/ADR integrations should be retained with the run.

### 8. Destroy only after preservation

Do not manually delete the VM before collection, hashing and preservation complete. The project lifecycle intentionally places **preserve before destroy**.

### 9. Validate after changes

```bash
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/validate-recipes.sh
go test ./...
gofmt -d cmd/policyctl/main.go
```

GitHub Actions performs the project validation on pushes and pull requests.

## Goose operator workflow

| Step | Purpose |
|---|---|
| Discover | read contracts, experiment and recipes |
| Validate | reject invalid recipe references |
| Preflight | inspect host/VM/tool capabilities |
| Install | install declared missing prerequisites |
| Plan | create proposed execution sequence |
| Review | identify risk and policy implications |
| Approve | obtain required human approval |
| Provision | create disposable Lima/QEMU VM |
| Instrument | start telemetry before the target action |
| Execute | run approved workload/tools |
| Collect | capture runtime artifacts and audit |
| Reduce | deterministically reduce large evidence |
| Forensics | analyse preserved evidence |
| Verify | independently test important findings |
| Report | create report and evidence manifest |
| Preserve | hash/preserve evidence |
| Destroy | remove VM after preservation |

Goose is the reference **operator/executor**, not the security boundary. VM isolation, OS permissions, mount controls, credential separation, network controls and approval workflows provide enforcement.

## Required capabilities

The authoritative tool contract is `recipes/tools/security-research.yaml`: required host tools are Git, Bash, Python 3, QEMU and Lima; optional host tools include `jq`, `yq`, `rg`, `tcpdump`, `strace`, `lsof` and Numbat. VM tools are declared separately. Installation policy is in `recipes/install/`.

## Agent adapter instructions

An adapter integrates an agent product with the same project contracts. Do not fork experiment semantics.

**OpenCode**
1. Start OpenCode in the repository.
2. Read `AGENTS.md` and the applicable Markdown contract.
3. Resolve the same `recipes/` composition.
4. Map tools/MCP/skills to registry-approved capabilities.
5. Honor `policyctl` and approval decisions.
6. Preserve the same lifecycle, blackboard, audit and evidence handoffs.

**Grok Build**
1. Integrate Grok Build only at the adapter boundary.
2. Expose registry-approved tools/MCP only.
3. Preserve policy, audit, evidence and verification semantics.
4. Keep Grok-specific prompts/tool wiring outside shared recipes.
5. Use `NOT_DEPLOYED` for unavailable integration.

**Antigravity**
1. Follow `antigravity/README.md` and `11-current-antigravity-reference.md`.
2. Load canonical `.agents/` roles/skills and the MCP registry.
3. Resolve the same experiment, VM, workload, instrumentation and audit recipes.
4. Keep Antigravity-specific wiring outside experiment semantics.
5. Preserve evidence and independent verification.

![Adapter boundary](docs/images/ai-security-lab-project-architecture.svg)

## Experiments

An experiment is a reproducible **question + scope + workload + environment + instrumentation + evidence plan + acceptance criteria**. It is not just a command.

For beginners, `go-install-001` is the reference end-to-end experiment. Read its Markdown contract first, then trace the recipes it selects. Runtime `PASS` requires evidence; configuration or an AI assertion is not proof.

## Blackboard

The **blackboard** is structured coordination state shared between agent stages. It prevents later stages from depending on conversational memory. Record requested, approved, executed, observed, evidence references, uncertainty and next action. Blackboard data is **coordination metadata, not evidence**.

## Instrumentation

Instrumentation starts **before** the target action. Typical layers include process/system-call, network/DNS, filesystem, host, agent/tool telemetry and evidence-integrity layers. Preserve raw telemetry and deterministically reduce large datasets before LLM analysis where practical.

## Agent monitoring stack

- **OpenTelemetry:** common telemetry model for agent/tool traces, spans and events.
- **Phoenix:** optional OpenTelemetry-oriented LLM/agent observability surface.
- **Numbat:** optional security/agent-observability capability declared in the tools recipe.
- **ADR / agent detection and response:** optional security observation/response layer.

These are observability/detection components, **not security boundaries**. Missing integrations are recorded as `NOT_DEPLOYED` rather than silently substituted.

## MCP, skills and tool calls

`recipes/mcp/registry.yaml` is the source of truth for approved MCP capabilities. Public exposure is denied; privileged/VM capabilities require approval; secrets must never be MCP arguments.

`recipes/skills/registry.yaml` declares reviewed skills. Skills are **instructions, not privileges**.

`recipes/tools/security-research.yaml` declares host/VM tools and requires observable tool calls. Unknown tools/installers are not silently accepted. Material tool/MCP/skill/policy decisions belong in the audit layer.

## Recipes: customize safely

Recipes are **small composable configuration units**. Do not make `recipes/goose/project.yaml` a monolith.

```text
What changes?
 ├─ experiment       → experiments/
 ├─ workload         → workloads/
 ├─ VM                → lima/profiles/
 ├─ host              → host/
 ├─ tools/install     → tools/ or install/
 ├─ telemetry         → instrumentation/
 ├─ agent telemetry   → agent-monitoring/
 ├─ agent role        → agents/
 ├─ execution order  → orchestration/ or stages/
 ├─ routing           → routing/
 ├─ MCP/skill        → mcp/ or skills/
 ├─ audit             → audit/
 └─ report            → reporting/
```

Safe customization: read `AGENTS.md`, choose the narrowest recipe family, keep secrets out of YAML, keep privileged operations explicit, reference the recipe from experiment composition, validate, run through the selected adapter and preserve evidence.

## Artifacts

Artifacts are durable outputs that allow a researcher to understand a run without trusting an AI conversation. Preserve before VM destruction, hash important evidence, never commit secrets, and make reports reference their evidence.

## policyctl

`policyctl` is intentionally narrow: host/security policy plus the local token dashboard. It is not the project controller, experiment runner, sandbox or agent harness.

```bash
./policyctl show
./policyctl validate
./policyctl check --action credentials
./policyctl check --action mounts
./policyctl check --action host-root
./policyctl check --action sudo
./policyctl check --action vm
./policyctl check --action network
./policyctl check --action git-write
./policyctl check --action push
./policyctl token-dashboard
```

A policy decision is not enforcement by itself; the adapter must honor it and host/VM controls enforce it.

## AI disclaimer and responsible use

AI-generated plans, commands, explanations, code, interpretations and findings can be wrong, incomplete, stale, unsafe or overconfident. They are **not evidence by themselves**. Human researchers remain responsible for authorization, scope, approvals, safety and final interpretation.

Use the lab only against systems, software and workloads you own or are explicitly authorized to test. Never provide an agent with credentials or unrestricted host access merely because a prompt requests it.

## Security model

- Untrusted workloads run inside disposable VMs.
- Host credentials and unrestricted host mounts are denied.
- Privileged/destructive actions require approval.
- Instrumentation starts before the target action.
- Evidence is preserved and hashed before VM destruction.
- Public MCP/gateway exposure is denied by default.
- Local services bind to localhost by default.
- Important findings are independently verified.
- Missing capabilities are `NOT_DEPLOYED`, not silently substituted.

`policyctl`, prompts, skills and MCP are not the security boundary. The VM/OS and host controls provide enforcement.

## License and notice

**MIT License — Copyright (c) 2026 Opposum0112.**

Permission is granted to use, copy, modify, merge, publish, distribute, sublicense and sell copies of this software and associated documentation, subject to the MIT License conditions. The software is provided **AS IS**, without warranty or liability.

**Responsible-use notice:** this is a personal, isolated AI-assisted security research laboratory. It is not a hosted service and does not grant permission to test systems you do not own or operate. Untrusted workloads should run in disposable Lima/QEMU VMs; do not expose credentials, public MCP/gateway services or observability dashboards; preserve evidence before destroying VMs; and do not claim a component was exercised unless it actually ran.

Third-party software retains its own licenses. The repository `LICENSE` and `NOTICE` files are authoritative.

## Documentation

See `01-deployment-architecture.md`, `02-system-requirements.md`, `03-deployment-runbook.md`, `04-security-model.md`, `05-multi-agent-operating-model.md`, `06-observability-and-evidence.md`, `07-experiment-framework.md`, `08-go-install-001.md`, `09-operations-and-maintenance.md`, `10-validation-and-acceptance.md`, `11-current-antigravity-reference.md`, `AI-DISCLAIMER.md`, `CONTRIBUTING.md` and `SECURITY.md`.

## Acceptance states

| State | Meaning |
|---|---|
| `PASS` | runtime behavior demonstrated with evidence |
| `PARTIAL` | capability worked but coverage/evidence is incomplete |
| `FAIL` | tested behavior did not meet the contract |
| `NOT_DEPLOYED` | capability unavailable or intentionally disabled |

**Configuration is not evidence. AI assertions are not evidence. Runtime artifacts, deterministic measurements and independent verification are evidence.**

## License files

- `LICENSE` — full MIT license.
- `NOTICE` — responsible-use and third-party software notice.
