# 🦝 Cusimanse

> Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.

Cusimanse prepares a researcher host, selects exactly one primary terminal agent, runs workloads inside disposable Lima/QEMU VMs, collects evidence, independently verifies findings, and preserves artifacts before VM destruction.

## Architecture

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

```text
Researcher
   │
   ▼
Go front door / preflight
   ├── Host + VM
   ├── Primary Agent Adapter
   ├── Control + Learning
   └── Observability + Governance
              │
              ▼
       ONE primary agent shell
              │
       YAML / Taskflow / LangGraph
              │
              ▼
       Lima + QEMU disposable VM
              │
        workload + evidence
              │
       verify → learn → preserve

policyctl ───────► independent host-side policy
OTEL/Phoenix/Numbat/Aegis ─► observability/governance
CrewAI ──────────► optional specialist-role layer
Skills/MCP ──────► declared capabilities/integrations
```

### Architecture diagrams

The repository retains the architecture diagrams from the architecture, agent/adaptor and CrewAI work:

- `docs/architecture/cusimanse-architecture.svg` — primary system architecture.
- `docs/images/cusimanse-deployment-architecture.svg` — deployment view.
- `docs/images/cusimanse-refactored-architecture.svg` — refactored architecture view.
- `docs/images/cusimanse-self-learning-loop.svg` — learning/promotion loop.
- `docs/images/cusimanse-crew-orchestration.svg` — optional CrewAI role layer.
- `docs/images/cusimanse-mascot.svg` — project identity.
- `docs/images/ai-security-lab-architecture.svg` and `ai-security-lab-project-architecture.svg` — retained historical architecture references.

## Researcher quick start

There is one recommended setup path and one short research path.

### 1. Prepare the researcher host

From the repository root:

```bash
./scripts/cusimanse-host.sh
```

The Go front door handles these planes interactively:

1. **Host + VM** — Git, Bash, Python, Ruby, Go, QEMU and Lima.
2. **Primary Agent** — select exactly one adapter.
3. **Control + Learning** — YAML tooling, LangGraph-related tooling and research/learning utilities.
4. **Observability + Governance** — OpenTelemetry, Phoenix, Numbat and Aegis.
5. **Preflight** — host and capability checks.
6. **Policy** — optional independent `policyctl validate`.

Windows uses WSL2 for the Linux Lima/QEMU path. Native package managers are preferred with supported upstream/release/source fallbacks. Unavailable capabilities remain `NOT_DEPLOYED`.

Manual alternatives remain available:

```bash
bash ./scripts/prerequisites.sh
bash ./scripts/agent-preflight.sh
bash ./scripts/install-observability.sh
./policyctl validate
```

### 2. Select and verify one primary adapter

| Adapter | Interactive shell | Verify |
|---|---|---|
| Goose | `goose` | `goose --help` |
| OpenCode | `opencode` | `opencode --help` |
| Grok Build | `grok` | `grok --help` |
| Antigravity | `agy` | `agy --help` |
| Pi | `pi` | `pi --help` |
| Hermes | `hermes` | `hermes --help` |
| Codex | `codex` | `codex --help` |
| Prime Agent | `prime-agent` | `prime-agent --help` |
| Claude Code | `claude` | `claude --help` |
| Devin | provider-managed | provider check |

For manual selection:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=prime-intellect
prime-agent --help
prime-agent
```

Use the native command form confirmed by that installed release. Do not copy flags between adapters. Goose is the reference adapter, not a permanent dependency.

### 3. Run the standard Cusimanse task

Inside the selected agent shell, provide:

```text
Act as the primary operator for one Cusimanse security-research case.

Read the applicable recipes under recipes/agents, recipes/adapters,
recipes/campaigns, recipes/workflows, recipes/orchestration and recipes/learning.
Use the selected adapter contract and follow:
Discover → Validate → Retrieve → Plan → Review → Approve →
Provision VM → Instrument → Execute → Collect → Analyze →
Verify → Learn → Promote → Preserve → Destroy

Rules:
- Run untrusted workloads only inside the disposable Lima/QEMU VM.
- Do not invoke or modify policyctl; it is host-side and outside the agent control plane.
- Do not expose host credentials to workloads or learned skills.
- Retrieval never grants execution authority.
- Preserve raw evidence, telemetry, audit records and hashes before VM destruction.
- New learned procedures remain CANDIDATE until replay, independent verification,
  provenance, capability and human-approval gates pass.
- If a capability is unavailable, report NOT_DEPLOYED.
- Never claim PASS without runtime evidence.

At completion report case ID, campaign, state, tools used, VM state,
evidence paths, verification result, skill state and failed gates.
```

### 4. Run the reference integration experiment

Ask the selected agent:

```text
Run experiments/go-install-001 as a Cusimanse integration test.
Use the configured campaign/workflow and execute the workload inside a disposable
Lima/QEMU VM. Start instrumentation before execution; collect raw evidence,
telemetry and audit records; independently verify the result; preserve hashes;
then destroy the VM. Do not bypass policy controls or modify policyctl.
Report PASS, PARTIAL, FAIL or NOT_DEPLOYED strictly from evidence.
```

Inspect the result from the normal researcher shell:

```bash
find evidence blackboard runs experiments/go-install-001 -type f -print 2>/dev/null
```

A runtime `PASS` requires actual VM execution and preserved evidence. Static CI success is not a sandbox-resistance test.

### 5. Test adapter equivalence

Repeat the same campaign and task contract with another adapter:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=hermes
hermes
```

Then try Prime Agent, Goose, OpenCode, Grok Build, Antigravity, Pi or Codex as available. The objective is to verify that changing the operator does not change the research contract, evidence requirements, policy separation or VM/OS security boundary.

### 6. Test learning

After a completed case:

```text
Create one reusable research procedure from this case as a CANDIDATE SKILL.
Include SKILL.md, deterministic helpers where appropriate, references, evaluation
cases, capability/risk metadata and provenance. Do not promote it and do not alter
original evidence.
```

Replay the candidate on a **distinct artifact**, independently verify it, then require human approval before promotion:

```text
CANDIDATE → replay → distinct artifact → independent verification
→ provenance/capability checks → human approval → VALIDATED → retrieval index
```

## Command interfaces

| Plane | Interface | Researcher use |
|---|---|---|
| Front door | `./scripts/cusimanse-host.sh` | Recommended interactive setup |
| Host | `bash ./scripts/prerequisites.sh` | Manual dependency setup/repair |
| Host | `bash ./scripts/agent-preflight.sh` | Capability preflight |
| Agent | `goose`, `opencode`, `grok`, `agy`, `pi`, `hermes`, `codex`, `prime-agent`, `claude` | Primary operator shell |
| Policy | `./policyctl validate` | Validate host policy |
| Policy | `./policyctl show` | Review policy |
| Policy | `./policyctl check --action <action>` | Evaluate/audit policy decision |
| Recipes | `find recipes -name '*.yaml' -print` | Discover contracts |
| VM | `limactl list` | List VMs |
| VM | `limactl shell <vm>` | Controlled VM shell |
| VM | `limactl stop <vm>` | Stop VM |
| VM | `limactl delete <vm>` | Destroy after evidence preservation |
| Evidence | `find evidence blackboard runs -type f -print` | Locate evidence |
| Evidence | `sha256sum <file>` | Verify artifact integrity |
| Skills | `find .agents/skills -name SKILL.md -print` | Discover skills |
| Validation | `bash ./scripts/tests/validate-project.sh` | Repository validation |
| Validation | `bash ./scripts/tests/architecture-refactor.sh` | Architecture contract validation |
| Validation | `go test ./...` | Go tests |

## Skills and MCP

Skills use the repository's `SKILL.md`/Markdown instruction model and are registered in `recipes/skills/registry.yaml`. The registry includes security research, triage, static/dynamic analysis, network analysis, malware analysis, reverse engineering, threat intelligence, vulnerability research, dependency analysis, detection engineering, forensics, IOC extraction, ATT&CK mapping, evidence reduction, independent verification, skill authoring, supply-chain auditing and token optimization.

External skills are **candidate-review-required** until provenance, license, scripts, permissions, network behavior and capabilities are reviewed and copied into the repository. Skill presence or retrieval does not grant privilege.

MCP integrations are declared in `recipes/mcp/registry.yaml` and `recipes/mcp/connectors.yaml`. Default transport is stdio, bind address is loopback, public exposure is denied, privileged/write/VM capabilities require approval, and secrets are never passed through MCP arguments. External reference data is enrichment, not evidence.

Reference sources include MITRE ATT&CK, CISA KEV, NVD/CVE, CISA advisories, Sigma, YARA, Suricata, OWASP, URLhaus, MalwareBazaar, AbuseIPDB and AlienVault OTX. Record source and retrieval time and independently verify important findings.

## CrewAI orchestration

CrewAI is an **optional specialist-role layer**, not a security boundary, evidence store or competing project controller. It operates through `recipes/orchestration/crewai.yaml` and returns structured role results to the selected primary agent.

Roles include planner, researcher, runtime analyst, forensics, detection analyst, verifier and reporter. CrewAI cannot bypass the primary agent, policy, approval, evidence-preservation or VM/OS controls. Missing CrewAI capability is `NOT_DEPLOYED`.

See `crewai/README.md` and `docs/images/cusimanse-crew-orchestration.svg`.

## Policy control

`policyctl` is deliberately **outside the agent control plane**.

```bash
./policyctl validate
./policyctl show
./policyctl check --action credentials
./policyctl check --action mounts
./policyctl check --action host-root
./policyctl check --action sudo
./policyctl check --action vm
./policyctl check --action network
./policyctl check --action git-write
./policyctl check --action crew-orchestration
```

The primary agent must not redefine, weaken or bypass these controls. VM/OS, filesystem/mount, privilege, credential and network controls remain the actual enforcement boundary.

## Observability and governance

The observability plane contains OpenTelemetry, Phoenix, Numbat and Aegis. These components provide monitoring/governance and are **not** workload-isolation boundaries. Lima/QEMU and host/OS controls remain authoritative.

Recipes:

```text
recipes/observability/numbat.yaml
recipes/observability/aegis.yaml
```

## Research lifecycle

```text
Discover → Validate → Retrieve → Plan → Review → Approve
→ Provision VM → Instrument → Execute → Collect → Analyze
→ Verify → Learn → Promote → Preserve → Destroy
```

YAML recipes specify semantics. The selected primary agent operates them. LangGraph provides stateful execution where configured. CrewAI provides optional specialist-role coordination. Durable evidence/case storage remains independent.

## Validation

```bash
./policyctl validate
bash ./scripts/agent-preflight.sh
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/architecture-refactor.sh
go test ./...
```

For runtime acceptance, also run `experiments/go-install-001` and preserve actual VM evidence. Static validation does not prove sandbox resistance.

## System requirements

- Linux or macOS directly; Windows through WSL2.
- 4+ CPU cores recommended.
- 16 GB RAM recommended.
- 40+ GB free disk recommended.
- Hardware virtualization enabled where applicable.
- Network access only for permitted installation/research enrichment.
- One supported primary agent for agent-driven cases.

See `docs/system-requirements.md` and `docs/ARCHITECTURE-REFACTOR-RUNBOOK.md` for detailed requirements and runtime procedures.

## Security invariants

- Lima/QEMU disposable VM is the workload execution boundary.
- `policyctl` remains outside the agent control plane.
- Exactly one primary agent owns the runtime operator lifecycle for a case.
- Host credentials are not exposed to workloads or learned skills.
- Public MCP exposure is denied by default.
- Observability, governance, skills, MCP and orchestration frameworks are not isolation boundaries.
- Retrieval does not grant execution authority.
- Evidence is preserved before VM destruction.
- Learned capabilities require replay and independent verification before promotion.
