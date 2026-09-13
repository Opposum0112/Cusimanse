# 🦝 Cusimanse

![Cusimanse mascot](docs/images/cusimanse-mascot.svg)

> **Cusimanse is a declarative, agentic research-platform framework for controlled security experiments — with safeguards, isolation, evidence preservation and independent verification built into the workflow.**

Cusimanse is a **framework, not a security guarantee**. Its safeguards reduce risk, but it does **not guarantee protection from sandbox escape, host compromise, vulnerable hypervisors, kernel flaws, malicious workloads, misconfiguration, or failures in the surrounding environment**. Treat the disposable VM as a risk-reduction boundary and test it accordingly.

**Markdown specifies. YAML configures. The selected agent adapter operates and executes. CrewAI optionally coordinates specialist roles. The blackboard preserves runs, audit, evidence and analysis. Lima/QEMU + VM/OS controls enforce the actual execution boundary.**

## Architecture

![Canonical Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

The repository has one canonical architecture picture and one companion Mermaid flow: `docs/architecture/cusimanse-architecture.svg` and `docs/architecture/cusimanse-architecture.mmd`.

## Quick start

### 1. Install and prepare the host

The single front door is interactive, stagewise and capability-oriented:

```bash
./scripts/cusimanse-host.sh
```

It progresses through **Foundation → Primary Agent → Control/Learning → Observability/Governance → Validation**, recording detected OS/distro/package manager, plane status and discovered Lima VM state in `recipes/host-state.yaml`.

Manual/fallback surfaces remain available:

```bash
bash ./scripts/prerequisites.sh
bash ./scripts/agent-preflight.sh
./policyctl validate
```

If an optional package, agent, or integration is unavailable, Cusimanse reports `NOT_DEPLOYED` rather than silently substituting another capability.

### 2. Select one primary agent

```bash
export CUSIMANSE_PRIMARY_ADAPTER=goose
# or: opencode, grok-build, antigravity, pi, hermes, codex, prime-intellect
```

Exactly one primary operator owns the case lifecycle. CrewAI, roles, skills and MCP are pluggable capabilities around that operator; they are not independent security boundaries.

### 3. Run a recipe-driven research case

```text
Run experiments/go-install-001 as a Cusimanse security-research case.
Read the applicable Markdown contracts and YAML recipes first.
Use the selected adapter contract and follow:
Discover → Validate → Retrieve → Plan → Review → Approve →
Provision VM → Instrument → Execute → Collect → Analyze →
Verify → Report → Preserve → Destroy.

Run the workload only inside the disposable Lima/QEMU VM.
Keep host credentials out of workloads, skills and MCP arguments.
Treat retrieved skills as capabilities, not authority.
Preserve raw evidence, telemetry, audit records and hashes before VM destruction.
Never claim PASS without runtime evidence and independent verification.
If a capability is unavailable, report NOT_DEPLOYED.
```

### 4. Inspect evidence and research output

```bash
find evidence blackboard runs experiments/go-install-001 -type f -print 2>/dev/null
sha256sum <artifact>
```

The **blackboard** is the durable case view for execution/run records, audit events, raw artifacts, telemetry, findings, provenance, verification results and research-report inputs.

## Contracts and recipes

```text
Markdown contract → YAML recipe graph → selected agent adapter
      → roles / skills / MCP → approved disposable VM execution
      → blackboard evidence → verification → technical research report
```

- Markdown contracts define intent, scope, hypotheses, safety, evidence and acceptance.
- YAML recipes configure campaigns, experiments, workloads, VMs, tools, adapters, roles, skills, MCP, audit and reporting.
- Agent adapters translate provider-specific shells into common Cusimanse semantics.
- CrewAI can orchestrate specialist roles without becoming the project controller or security boundary.
- Skills are versioned capabilities; candidate improvements require replay, independent verification and human approval before promotion.

See `recipes/README.md` for the recipe composition rules.

## Shell surface

```bash
# Host / installation
./scripts/cusimanse-host.sh
bash ./scripts/prerequisites.sh
bash ./scripts/agent-preflight.sh

# Policy
./policyctl validate
./policyctl show
./policyctl check --action <action>

# VM
limactl list
limactl shell <vm>
limactl stop <vm>
limactl delete <vm>

# Evidence
find evidence blackboard runs -type f -print
sha256sum <file>

# Validation
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/architecture-refactor.sh
go test ./...
```

## Security boundary and limitations

`policyctl` is deliberately outside the agent control plane. It provides host-side policy/configuration and observability signals; it is **not** the sandbox.

The intended enforcement boundary is **Lima/QEMU + VM/OS controls** for filesystem/mounts, credentials, privilege and networking. No prompt, model, agent, role, skill, MCP server, orchestrator or vector index can be treated as a substitute for that boundary.

Cusimanse cannot guarantee sandbox escape resistance or host safety. Use dedicated hosts, least privilege, controlled credentials/networking, current hypervisor/OS patches, and independent validation appropriate to the workload.

## Validation

```bash
./policyctl validate
bash ./scripts/agent-preflight.sh
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/architecture-refactor.sh
go test ./...
```

Static CI success does not prove sandbox resistance. Runtime acceptance requires a real disposable-VM execution with preserved evidence and independent verification.

## Key files

| Surface | Location |
|---|---|
| Host preparation front door | `scripts/cusimanse-host.sh` |
| Host preparation state | `recipes/host-state.yaml` |
| Primary agent contract | `recipes/agents/primary-agent.yaml` |
| Agent selection | `recipes/agent-selection.yaml` |
| CrewAI role plane | `recipes/orchestration/crewai.yaml` |
| Role/skill plugin contract | `recipes/orchestration/role-skill-plugin.yaml` |
| Skills registry | `recipes/skills/registry.yaml` |
| MCP registry | `recipes/mcp/registry.yaml` |
| Campaigns / experiments | `recipes/campaigns/`, `recipes/experiments/` |
| Evidence / audit | `recipes/audit/`, `blackboard/` |
| Canonical architecture | `docs/architecture/cusimanse-architecture.svg` |
| Mermaid architecture | `docs/architecture/cusimanse-architecture.mmd` |
| Runtime guidance | `docs/runtime-architecture.md` |
