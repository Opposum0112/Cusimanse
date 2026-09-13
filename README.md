# 🦝 Cusimanse

**Cusimanse is a declarative, fully multiagentic security-research platform for controlled experiments.** Markdown contracts define research intent and safety constraints; YAML recipes define experiments, agents, roles, skills, instrumentation, VMs, gateways and reporting; the installation script is the host front door; `policyctl` is the governance boundary; and Lima/QEMU VMs provide the execution/isolation boundary.

> **Important:** Cusimanse reduces research risk; it is not a security guarantee. VM/OS isolation must be tested and independently assessed.

## Architecture

![Cusimanse architecture](docs/architecture/cusimanse-architecture.svg)

## 1. Install and prepare the host

Run these in the **normal host shell**:

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout architecture-refactor
./scripts/cusimanse-host.sh
exec "$SHELL" -l
```

Validate the prepared host:

```bash
./policyctl validate
./scripts/agent-preflight.sh
./scripts/tests/production-validation.sh
```

The installer prepares prerequisites, Lima/QEMU support, the selected primary agent, research tools, observability/governance tooling and model gateways. Installation is not the runtime acceptance test.

## 2. Research lifecycle

You do **not** type every lifecycle stage as a separate shell command. The lifecycle is the execution contract followed by the selected agent/operator shell:

```text
discover → validate → preflight → plan → review / human approval
→ provision disposable VM → start VM instrumentation → run approved workload
→ collect evidence + telemetry → hash / preserve evidence → analyze evidence
→ independent verification → generate research report → preserve final outputs
→ destroy disposable VM
```

The normal host shell prepares and validates. The selected primary agent owns the approved research lifecycle. If a gate fails, the run stops rather than silently skipping it.

## 3. Agent/operator shell and adapter matrix

The canonical adapter registry is `recipes/agents/adapter-matrix.yaml`. It records native adapter invocation and acceptance status. The matrix covers Goose, OpenCode, Grok Build, Antigravity, Pi, Hermes, Prime Agent, Codex, Claude Code and Devin.

A matrix entry is **not** proof of deployment. A candidate adapter must pass host preflight and a disposable-VM end-to-end test before runtime acceptance. See `docs/agent-shell-runbook.md` for native adapter commands and the shell/agent boundary.

## 4. Fully multiagentic execution

Cusimanse uses specialist roles including Planner, Researcher, Runtime Analyst, Forensics Analyst, Detection Analyst, Analysis Agent, Verifier and Report Generator. CrewAI is an **optional orchestration implementation** for role/task delegation; it is not the security boundary and cannot override `policyctl`, approvals or VM/OS controls.

Skills and MCP are declarative and pluggable. Skills may contain instructions, scripts, evaluations and provenance. Candidate learned/imported skills require replay/evaluation, independent verification and human approval before promotion. MCP/tool plugins are scoped capabilities, not the execution boundary.

## 5. Declarative experiments

A new experiment is composed from Markdown contracts and YAML recipes:

```text
contracts/<case>.md                    # intent, scope, hypothesis, safety, acceptance
recipes/experiments/<case>.yaml        # workload + recipe graph
recipes/instrumentation/<case>.yaml    # VM-side instrumentation
recipes/lima/<profile>.yaml            # disposable VM profile
experiments/<case>/                    # case-specific files
```

The experiment graph composes workload, VM profile, **VM-only instrumentation**, agent adapter, specialist roles, skills, optional CrewAI, MCP/tool plugins, model gateway, evidence/analysis/reporting and governance/token accounting.

The installation front door is `./scripts/cusimanse-host.sh`; `./policyctl validate` is the governance boundary outside the agent control plane; Lima/QEMU + VM/OS controls provide the execution boundary.

## 6. Reference Go experiment

For `go-install-001`, give the selected primary agent the research task and require it to discover the contract and referenced recipes, plan the run, stop for human approval, provision the disposable VM, start declared VM-side instrumentation, execute the workload only inside the VM, collect evidence, independently verify findings, generate the report, preserve hashes and then destroy the VM.

The agent should return the run ID plus evidence, verification and research-report paths. Model output is not evidence.

## 7. Evidence and verification

A completed research run should contain raw evidence, VM telemetry, provenance/hashes, analysis, findings, independent verification and a technical research report. Verify it with:

```bash
./scripts/verify-run.sh <run-directory>
cd <run-directory>
sha256sum -c provenance/hashes.sha256
```

## 8. Token dashboard

After an experiment, from the normal host shell:

```bash
cusimanse-token-dashboard
```

The default ledger is `reports/token-usage/usage.json` and the default dashboard address is `127.0.0.1:8787`.

## 9. Instrumentation boundary

**Workload instrumentation is VM-only.** The host installs/prepares tooling; observation of the workload occurs inside the disposable Lima/QEMU VM. The instrumentation set is selected declaratively before execution and the agent must not invent additional instrumentation after execution starts.

## 10. Integration testing and runtime acceptance

### Static validation

Run this first from the repository root:

```bash
./scripts/tests/production-validation.sh
```

This validates repository structure, shell syntax, Go validation, recipe YAML, architecture/security assertions and required integrations. A successful static run is necessary but **does not prove Lima/QEMU runtime isolation or execution**.

### Real Lima/QEMU runtime test

**Important: the actual Lima/QEMU runtime test cannot truthfully be marked PASS from GitHub's normal hosted CI.** It must be executed on a suitable research host with Lima/QEMU available.

Run:

```bash
./scripts/tests/production-validation.sh

export CUSIMANSE_LIMA_PROFILE=recipes/lima/profiles/security-research.yaml
./scripts/tests/runtime-integration.sh

./scripts/verify-run.sh reports/runtime/<run-id>
```

The runtime test provisions a disposable VM, executes the safe smoke workload inside that VM, captures VM-side evidence/telemetry, creates a verifier-compatible run structure and SHA-256 manifest, and deletes the VM after preservation.

**Runtime acceptance is PASS only if the runtime test actually completes successfully and the generated run passes `scripts/verify-run.sh`.** GitHub hosted static CI may validate the scripts and repository, but it must not be reported as proof of Lima/QEMU runtime acceptance unless the CI runner itself provides and exercises the required Lima/QEMU environment.

The runtime smoke test is intentionally scoped: it does not claim to validate every agent adapter, optional instrumentation backend, gateway, observability integration or full production security posture.

## Key paths

```text
contracts/                              Research intent and safety constraints
recipes/                                Declarative configuration
recipes/experiments/                    Experiment definitions
recipes/instrumentation/                VM-only workload instrumentation
recipes/agents/                         Agent contracts and adapter matrix
recipes/roles/                          Specialist roles
recipes/skills/                         Skill registry/references
recipes/mcp/                            MCP registry/connectors
recipes/orchestration/                  Optional CrewAI orchestration
recipes/gateways/                       LiteLLM / OmniRoute
recipes/lima/                           Disposable VM profiles
experiments/                            Research cases
blackboard/                             Durable evidence/case model
scripts/cusimanse-host.sh               Installation/preparation front door
scripts/verify-run.sh                   Run/evidence verification
scripts/tests/production-validation.sh  Static validation
scripts/tests/runtime-integration.sh   Lima/QEMU runtime validation
policyctl                               Governance/policy boundary
```

## Safety boundary

Keep credentials out of workloads, avoid unsafe host mounts, use appropriately isolated networking, review contracts and recipes before approval, preserve evidence before VM destruction, and independently verify important findings. Neither the model, role, skill, CrewAI, MCP, gateway nor report generator is the security boundary; `policyctl` remains outside the agent control plane and VM/OS controls enforce execution isolation.
