# 🦝 Cusimanse

<p align="center">
  <img src="docs/images/cusimanse-mascot.svg" alt="Cusimanse mascot — curious cyber raccoon for security research" width="1000">
</p>

> **Autonomous, agentic security research platform for controlled workload detonation, runtime analysis, anomaly detection and evidence extraction inside disposable virtual machines.**

[![CI](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml/badge.svg)](https://github.com/Opposum0112/Cusimanse/actions/workflows/validate.yml) [![Go](https://img.shields.io/badge/Go-1.23%2B-00ADD8?logo=go)](https://go.dev/) [![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash)](https://www.gnu.org/software/bash/) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![Release](https://img.shields.io/github/v/release/Opposum0112/Cusimanse?include_prereleases&label=release)](https://github.com/Opposum0112/Cusimanse/releases)

Cusimanse is named after the hyper-curious mongoose that obsessively flips over every leaf and stone to uncover hidden details. The platform applies the same curiosity to software workloads: provision an isolated environment, observe execution, collect evidence, analyze behavior and preserve artifacts for independent verification.

## About

Cusimanse is a **research and experimentation platform**, not a production malware sandbox. It combines disposable Lima/QEMU virtual machines with agent adapters, composable recipes, instrumentation, policy checks, evidence handling and optional observability integrations. The design keeps experiment semantics independent from the agent used to operate them.

**Status:** `v1.0.0-beta.1` — early beta for controlled security research and engineering experimentation. APIs, recipes and integrations may change between beta releases.

## What Cusimanse does

```text
Experiment contract
       ↓
Agent adapter
(Goose / OpenCode / Grok Build / Antigravity)
       ↓
recipes + MCP + skills + policy
       ↓
plan → review → approval
       ↓
disposable Lima / QEMU VM
       ↓
instrument → execute → collect
       ↓
blackboard + evidence + telemetry
       ↓
reduce → forensics → verify
       ↓
report → preserve → destroy
```

The platform is **agent-neutral**. Goose is the current reference adapter, not the project identity. Adapter-specific prompts, tool wiring and integration details stay at the adapter boundary; experiment semantics remain shared.

## Deployment architecture

The deployment model separates the **agent/operator plane** from the **VM/OS enforcement boundary**. Shared contracts define experiment semantics; adapters operate approved actions; disposable Lima/QEMU VMs contain the workload; instrumentation and evidence pipelines provide the basis for analysis and verification.

![Cusimanse deployment architecture](docs/images/cusimanse-deployment-architecture.svg)

**Control flow:** `Intent → Contract → Adapter → Policy/Approval → Disposable VM → Instrument → Execute → Collect → Verify → Preserve → Destroy`

For the detailed deployment layers, boundaries and lifecycle, see [`01-deployment-architecture.md`](01-deployment-architecture.md).

## Security boundary

AI agents, prompts, skills, MCP servers and `policyctl` are **not** security boundaries. Enforcement comes from the VM/OS boundary, filesystem and mount controls, credential separation, network controls and explicit approval gates.

Key invariants:

- Untrusted workloads run in disposable VMs.
- Host credentials and unrestricted host mounts are denied.
- Privileged and destructive operations require approval.
- Public MCP/gateway exposure is denied by default.
- Instrumentation starts before the target workload.
- Evidence is preserved and hashed before VM destruction.
- Important findings require independent verification.
- Missing integrations are reported as `NOT_DEPLOYED`, never silently substituted.
- AI assertions are never treated as evidence.
- Public reference services receive only approved non-sensitive enrichment queries.

See [`04-security-model.md`](04-security-model.md) and [`SECURITY.md`](SECURITY.md).

## Quick start

### 1. Install prerequisites

```bash
./scripts/prerequisites.sh
```

### 2. Load the environment

```bash
source ./scripts/goose-env.sh
```

This configures project paths only. **Never place API keys, cloud credentials or secrets in the repository.**

### 3. Validate

```bash
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

### 4. Bootstrap the project

```bash
goose run --recipe recipes/install/project-bootstrap.yaml
```

### 5. Run the reference experiment

```bash
goose run \
  --recipe recipes/goose/project.yaml \
  --params experiment=go-install-001 \
  --params section=project
```

The lifecycle is:

```text
Discover → Validate → Preflight → Install → Plan → Review → Approve
→ Provision → Instrument → Execute → Collect → Reduce → Forensics
→ Independent verification → Report → Preserve → Destroy
```

## Recipes and composition

Recipes are intentionally small and composable. Do not turn the project recipe into a monolith.

| Concern | Recipe family |
|---|---|
| Experiments | `recipes/experiments/` |
| Workloads | `recipes/workloads/` |
| Routing | `recipes/routing/` |
| Installation | `recipes/install/` |
| Host profile | `recipes/host/` |
| VM profile | `recipes/lima/` |
| Tools | `recipes/tools/` |
| Instrumentation | `recipes/instrumentation/` |
| Agent monitoring | `recipes/agent-monitoring/` |
| Agent roles | `recipes/agents/` |
| Orchestration/stages | `recipes/orchestration/`, `recipes/stages/` |
| Reporting | `recipes/reporting/` |
| MCP | `recipes/mcp/` |
| Skills | `recipes/skills/` |
| Reference databases | `recipes/reference/` |
| Audit | `recipes/audit/` |

`recipes/goose/project.yaml` is the reference Goose adapter composition. Other adapters must consume the same project contracts.

## Security research skills

Cusimanse now provides a registry-driven security research skill layer. The registry covers:

- **Planning & triage:** experiment planning and workload triage
- **Static research:** static analysis, dependency/supply-chain analysis and reverse engineering
- **Runtime research:** dynamic analysis, malware analysis and network analysis
- **Threat research:** threat intelligence, vulnerability research and ATT&CK mapping
- **Detection:** YARA/Sigma-oriented detection engineering
- **Forensics:** IOC extraction, forensic preservation and evidence reduction
- **Verification:** independent verification and reproducible research reporting
- **Governance:** project audit and capability selection

The canonical catalog is [`recipes/skills/registry.yaml`](recipes/skills/registry.yaml), with detailed instructions under [`.agents/skills/`](.agents/skills/). Skills are **instructions, not privileges**. They cannot grant host access, credentials, VM control or network reachability.

### Skill selection model

```text
Experiment contract
       ↓
select reviewed skills
       ↓
select declared tools
       ↓
select approved MCP integrations
       ↓
policy + approval
       ↓
VM execution / evidence collection
       ↓
verification + report
```

Unknown or unavailable skills are `NOT_DEPLOYED`. Material skill selection and execution is audited.

## MCP integrations

MCP is the capability integration layer, not the security boundary. The registry includes controlled interfaces for repository inspection, evidence queries, disposable VM lifecycle, policy checks, telemetry and read-only security research references.

Current reference integrations include:

| Integration | Research use | Default access |
|---|---|---|
| Repository/evidence | inspect project and preserved evidence | read-only |
| VM control | disposable Lima lifecycle | approval-required |
| Policy | host/security policy decisions | policyctl-only |
| MITRE ATT&CK | behavior/technique reference | read-only |
| NVD / CVE | vulnerability research | read-only |
| CISA KEV | exploited-vulnerability prioritization | read-only |
| Sigma / YARA | detection research | read-only/local |
| URLhaus / MalwareBazaar | malicious URL/hash enrichment | optional read-only |
| AbuseIPDB / OTX | IOC enrichment | optional read-only |
| OpenTelemetry | telemetry ingestion/correlation | controlled |

See [`recipes/mcp/registry.yaml`](recipes/mcp/registry.yaml). Public MCP exposure is denied by default, privileged/write/VM operations require approval, and secrets are never passed through MCP arguments.

## Security research reference database

The curated reference catalog is [`recipes/reference/security-research-databases.yaml`](recipes/reference/security-research-databases.yaml). It includes authoritative and community sources such as MITRE ATT&CK, CISA KEV, NVD/CVE, CISA advisories, OWASP, Sigma, YARA, Suricata, URLhaus, MalwareBazaar, AbuseIPDB and AlienVault OTX.

Reference databases provide **enrichment, not workload evidence**. Every external result should retain source, retrieval time and confidence. Important findings must be independently verified. Public services must never receive secrets, credentials or sensitive private workload data.

## Security research tools

The tool catalog in [`recipes/tools/security-research.yaml`](recipes/tools/security-research.yaml) separates host, VM and analysis capabilities. Typical research tooling includes `jq`, `yq`, `rg`, `file`, `strings`, `readelf`, `objdump`, `nm`, `strace`, `lsof`, `ss`, `dig`, `tcpdump`, `bpftrace`, YARA and Sigma tooling where installed.

Tool availability is not proof of deployment. Missing tools are `NOT_DEPLOYED`; runtime use must be evidenced.

## Agent adapters

**Goose** — current reference operator/executor.

**OpenCode** — documented adapter target using `AGENTS.md`, shared recipes, registry-approved tools and the same evidence/audit lifecycle.

**Grok Build** — documented adapter target; Grok-specific wiring remains outside shared experiment semantics.

**Antigravity** — documented adapter target using the canonical `.agents/` roles/skills and MCP registry.

An adapter must not bypass policy, suppress audit, expose credentials, alter experiment semantics or claim `PASS` without evidence.

## Observation and evidence

Cusimanse treats runtime artifacts as the source of truth. Typical run output is:

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

The blackboard is coordination metadata, not evidence. Large raw evidence should be deterministically reduced before LLM analysis where practical while retaining the original artifacts.

Optional monitoring integrations include OpenTelemetry, Phoenix, Numbat and ADR. These provide observability/detection capabilities, not isolation boundaries.

## `policyctl`

`policyctl` is deliberately narrow: host/security policy configuration and the local token-usage dashboard. It is **not** the experiment controller, sandbox or agent harness.

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

## Validation and CI

Local validation includes recipe YAML parsing, shell syntax, architecture checks, Go formatting, `go vet`, unit tests, build checks and policy checks. Optional Python tests run when test modules are present.

GitHub Actions validates pushes and pull requests with least-privilege read permissions, concurrency cancellation, pinned action revisions, shell checks and Go checks. Dependency update automation covers Go modules and GitHub Actions.

The release workflow packages the repository from an immutable version tag and publishes checksums with the GitHub release. Release artifacts are generated from Git history rather than from a developer working tree.

Do not describe a capability as `PASS` unless it was actually exercised with evidence.

## Contributing

Bug reports, documentation fixes, tests, recipes and adapter improvements are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request.

- **Bug:** use the bug-report issue template and include reproducible steps, environment details and relevant logs with secrets removed.
- **Security vulnerability:** do **not** open a public issue; follow [`SECURITY.md`](SECURITY.md).
- **Feature/change:** explain the experiment or operator contract being improved and include tests or validation evidence where practical.
- **Pull requests:** keep changes focused, preserve security invariants and wait for required CI checks.

## Reporting bugs and security issues

For ordinary defects, use GitHub Issues with the **Bug Report** template. For vulnerabilities involving credential exposure, host escape, unsafe mounts, privilege escalation, malicious workflow changes or other security-sensitive behavior, use the private reporting process described in [`SECURITY.md`](SECURITY.md).

Please never publish credentials, tokens, private keys, sensitive workload data or unredacted forensic artifacts in an issue or pull request.

## Beta release policy

`v1.0.0-beta.*` releases are pre-production research releases. They are intended for authorized, controlled environments and may contain incomplete integrations or breaking changes. A beta release is not a claim of production security certification, sandbox escape resistance or operational completeness.

## Acceptance states

| State | Meaning |
|---|---|
| `PASS` | Runtime behavior demonstrated with evidence |
| `PARTIAL` | Capability worked but coverage/evidence is incomplete |
| `FAIL` | Tested behavior did not meet the contract |
| `NOT_DEPLOYED` | Capability unavailable or intentionally disabled |

Configuration is not evidence. AI output is not evidence.

## Responsible use

Use Cusimanse only against systems, software and workloads you own or are explicitly authorized to test. Untrusted workloads should run in disposable Lima/QEMU VMs. Never give an agent unrestricted host access or credentials merely because a prompt requests them.

AI-generated plans, commands, code and findings can be wrong, incomplete, stale or unsafe. Human researchers remain responsible for authorization, scope, approvals, safety and final interpretation.

## Documentation

- `01-deployment-architecture.md` — deployment architecture
- `02-system-requirements.md` — requirements
- `03-deployment-runbook.md` — deployment/runbook
- `04-security-model.md` — security model
- `05-multi-agent-operating-model.md` — multi-agent operation
- `06-observability-and-evidence.md` — observability and evidence
- `07-experiment-framework.md` — experiment framework
- `08-go-install-001.md` — reference experiment
- `09-operations-and-maintenance.md` — operations
- `10-validation-and-acceptance.md` — validation and acceptance
- `11-current-antigravity-reference.md` — Antigravity reference
- `AGENTS.md` — agent/adapter operating instructions
- `AI-DISCLAIMER.md` — AI limitations and responsible use
- `CONTRIBUTING.md` — contribution workflow
- `SECURITY.md` — security reporting and boundaries
- `RELEASE.md` — release process
- `recipes/skills/registry.yaml` — skill registry
- `recipes/mcp/registry.yaml` — MCP registry
- `recipes/reference/security-research-databases.yaml` — security research references

## License

**MIT License — Copyright (c) 2026 Opposum0112.** See [`LICENSE`](LICENSE) for the authoritative license and [`NOTICE`](NOTICE) for the responsible-use and third-party software notice.
