# 🦝 Cusimanse

> Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.

Cusimanse prepares a researcher host, selects one primary terminal agent, runs workloads inside disposable Lima/QEMU VMs, collects evidence, independently verifies findings, and preserves artifacts before VM destruction.

## Architecture

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

```text
Researcher
   │
   ▼
Go front door / preflight
   ├── Host + VM
   ├── Primary Agent
   ├── Control + Learning
   └── Observability + Governance
              │
              ▼
       Primary agent shell
              │
              ▼
   YAML / Taskflow / LangGraph
              │
              ▼
       Lima + QEMU VM
              │
              ▼
        Workload + evidence
              │
              ▼
 Verification → Learning → Preservation

policyctl ───────► independent host-side policy
OTEL/Phoenix/Numbat/Aegis ─► observability/governance
```

## Researcher quick start

There is one recommended installation path and one short research path.

### 1. Prepare everything

From the repository root:

```bash
./scripts/cusimanse-host.sh
```

The Go front door interactively handles the planes in order:

1. **Host + VM** — Git, Bash, Python, Ruby, Go, QEMU and Lima.
2. **Primary Agent** — choose exactly one operator: Prime Agent, Hermes or Goose.
3. **Control + Learning** — YAML tooling, LangGraph-related tooling and research/learning utilities.
4. **Observability + Governance** — OpenTelemetry, Phoenix, Numbat and Aegis.
5. **Preflight** — comprehensive host and capability check.
6. **Policy** — optional independent `policyctl validate`.

Installation uses the native package path where supported and an appropriate upstream/release/source fallback when the native path is unavailable. Windows uses WSL2. Locally verified configuration can update undefined YAML recipe fields; unavailable capabilities remain `NOT_DEPLOYED`.

If the front door is unavailable, the manual per-plane alternatives are:

```bash
bash ./scripts/prerequisites.sh
bash ./scripts/install-observability.sh
bash ./scripts/agent-preflight.sh
./policyctl validate
```

### 2. Select and start one adapter

The adapter is the **operator**, not the security boundary.

| Adapter | Start | Verify CLI |
|---|---|---|
| Prime Agent | `prime-agent` | `prime-agent --help` |
| Hermes | `hermes` | `hermes --help` |
| Goose | `goose` | `goose --help` |

Set the selected adapter explicitly when using manual operation:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=prime-agent
prime-agent --help
prime-agent
```

For another adapter, use the same workflow:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=hermes
hermes --help
hermes
```

or:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=goose
goose --help
goose
```

Only use command-line modes actually shown by that installed agent's `--help` output.

### 3. Give the agent the standard Cusimanse task

Paste this into the selected agent:

```text
Act as the primary operator for one Cusimanse security-research case.

Read the applicable recipes under recipes/agents, recipes/campaigns,
recipes/workflows, recipes/orchestration and recipes/learning.

Follow:
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

At completion report: case ID, campaign, state, tools used, VM state,
evidence paths, verification result, skill state and failed gates.
```

### 4. Run the reference integration test

Use the existing Go reference experiment:

```text
Run experiments/go-install-001 as a Cusimanse integration test.
Use the configured campaign/workflow and execute the workload inside a disposable
Lima/QEMU VM. Collect instrumentation, raw evidence and audit records; independently
verify the result; preserve evidence and hashes; then destroy the VM.
Do not bypass policy controls or modify policyctl.
Report PASS, PARTIAL, FAIL or NOT_DEPLOYED strictly from evidence.
```

After the agent finishes, inspect the preserved output from the normal researcher shell:

```bash
find evidence blackboard runs experiments/go-install-001 -type f -print 2>/dev/null
```

A real runtime PASS requires actual VM execution and preserved evidence. Static CI success alone is not a sandbox-runtime test.

### 5. Run adapter equivalence testing

Repeat the **same campaign, task prompt and evidence requirements** with another adapter:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=hermes
hermes
```

Then repeat with Prime Agent or Goose. The purpose is to verify that the operator can change while the Cusimanse research contract, evidence requirements, policy separation and VM security boundary remain unchanged.

### 6. Test learning and promotion

After a completed case, ask the agent:

```text
Create one reusable research procedure from this case as a CANDIDATE SKILL.
Include SKILL.md, deterministic helpers where appropriate, references, evaluation
cases, capability/risk metadata and provenance. Do not promote it and do not alter
original evidence.
```

Then retrieve and replay the candidate against a **distinct artifact**, independently verify the result, and obtain human approval before promotion. The promotion path is:

```text
CANDIDATE → replay → distinct artifact → independent verification
→ provenance/capability checks → human approval → VALIDATED → retrieval index
```

## Command interfaces

| Plane | Command/interface | Researcher use |
|---|---|---|
| Front door | `./scripts/cusimanse-host.sh` | Recommended interactive host preparation |
| Front door | `go run ./cmd/cusimanse-host` | Direct Go front door |
| Host | `bash ./scripts/prerequisites.sh` | Manual dependency installation/repair |
| Host | `bash ./scripts/agent-preflight.sh` | Manual comprehensive preflight |
| Agent | `prime-agent`, `hermes`, `goose` | Primary terminal operator |
| Policy | `./policyctl validate` | Validate active host policy |
| Policy | `./policyctl show` | Display active policy |
| Policy | `./policyctl check --action <action>` | Evaluate and audit a policy-controlled action |
| Policy | `./policyctl --help` | Display policy interface |
| Recipes | `find recipes -name '*.yaml' -print` | Discover research contracts |
| Recipes | `yq '.' <recipe>` | Inspect a recipe |
| VM | `limactl list` | List VMs |
| VM | `limactl shell <vm>` | Enter a VM for controlled work |
| VM | `limactl stop <vm>` | Stop a VM |
| VM | `limactl delete <vm>` | Destroy a VM after evidence preservation |
| Evidence | `find evidence blackboard runs -type f -print` | Locate preserved case output |
| Evidence | `sha256sum <file>` | Check artifact integrity |
| Skills | `find .agents/skills -name SKILL.md -print` | Discover skills |
| Validation | `bash ./scripts/tests/validate-project.sh` | Repository validation |
| Validation | `bash ./scripts/tests/architecture-refactor.sh` | Architecture contract validation |
| Validation | `go test ./...` | Go tests |

## Policy commands

`policyctl` is deliberately **outside the agent control plane**. The agent must not redefine, weaken or bypass it.

| Command | Use |
|---|---|
| `./policyctl validate` | Validate policy syntax and required policy values before execution or CI acceptance. |
| `./policyctl show` | Review the currently loaded policy. |
| `./policyctl check --action credentials` | Evaluate host credential access policy and record the decision. |
| `./policyctl check --action mounts` | Evaluate unrestricted host-mount policy. |
| `./policyctl check --action host-root` | Evaluate privileged host-filesystem access policy. |
| `./policyctl check --action sudo` | Evaluate sudo/privileged execution policy. |
| `./policyctl check --action vm` | Evaluate disposable-VM policy. |
| `./policyctl check --action network` | Evaluate localhost-service/network policy. |
| `./policyctl check --action git-write` | Evaluate repository write policy. |

Policy decisions are host-side controls; the primary agent does not own this interface.

## Observability and governance

The observability plane contains OpenTelemetry, Phoenix, Numbat and Aegis. The same front door installs and checks the plane, while `bash ./scripts/install-observability.sh` remains available for manual operation.

Numbat and Aegis are observability/governance components, **not workload-isolation boundaries**. Lima/QEMU and host/OS controls remain the security boundary.

Integration recipes:

```text
recipes/observability/numbat.yaml
recipes/observability/aegis.yaml
```

## OS support and fallback

| Host | Primary path | Fallback |
|---|---|---|
| Ubuntu/Debian | `apt` | supported upstream/release fallback |
| Fedora/RHEL-family | `dnf` | supported upstream/release fallback |
| Arch-family | `pacman` | supported upstream/release fallback |
| openSUSE/SUSE | `zypper` | supported upstream/release fallback |
| Alpine | `apk` | supported upstream/release fallback |
| macOS | Homebrew | supported upstream/release/source fallback |
| Windows | WSL2 | Linux path inside WSL2 |

For supported operating systems, the installer attempts the native path first and falls back when unavailable. A capability is only reported as deployed after local verification.

## Research lifecycle

```text
Discover → Validate → Retrieve → Plan → Review → Approve
→ Provision VM → Instrument → Execute → Collect → Analyze
→ Verify → Learn → Promote → Preserve → Destroy
```

Recipes specify research semantics. The selected primary agent operates them. LangGraph provides stateful execution. Evidence/case storage remains independent. Retrieval does not grant execution authority.

## Validation

Normal repository validation:

```bash
./policyctl validate
bash ./scripts/agent-preflight.sh
bash ./scripts/tests/validate-project.sh
go test ./...
```

Reference runtime validation uses `experiments/go-install-001` and the adapter-equivalence workflow above.

## System requirements

- Linux or macOS directly; Windows through WSL2.
- 4+ CPU cores recommended.
- 16 GB RAM recommended for VM and observability workloads.
- 40+ GB free disk recommended for VM images and evidence.
- Hardware virtualization enabled where applicable.
- Network access for permitted installation and research enrichment.
- One supported primary terminal agent for agent-driven cases.

See `docs/system-requirements.md` for detailed requirements and deployment constraints.

## Security invariants

- Lima/QEMU disposable VM is the workload execution boundary.
- `policyctl` remains outside the agent control plane.
- Host credentials are not exposed to workloads or learned skills.
- Public MCP exposure is denied by default.
- Observability and governance are not isolation boundaries.
- Retrieval does not grant execution authority.
- Evidence is preserved before VM destruction.
- Learned capabilities require replay and independent verification before promotion.
