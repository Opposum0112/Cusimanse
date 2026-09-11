# AI Security Lab

**Recipe-driven, Goose-operated, disposable security research platform.**

The lab is intentionally simple: **Markdown specifies the project, one YAML recipe configures it, Goose is the agentic orchestrator/operator/executor, and a separate policy CLI configures host safety policy.**

## Architecture

```text
Human / CI intent
        ↓
Markdown contracts
        ↓
ONE project YAML recipe
        ↓
GOOSE — agentic operator
  discover • plan • review • execute
  observe • collect • investigate
  verify • report • commit
        ↓
Policy CLI
(host/security policy configuration)
        ↓
Lima / QEMU + instrumentation
        ↓
Disposable workload VM
        ↓
Evidence → reduction → forensics
          → independent verification
          → report / token usage
```

### Core principle

> **Markdown specifies. YAML configures. Goose operates and executes. Policy CLI constrains. Evidence verifies.**

Goose owns the project workflow. The repository should not contain a second orchestration lifecycle implemented as a large Go controller.

## Why this architecture

The previous design separated many deterministic phases into a Go control plane. That added a second execution model beside Goose. The simplified design removes that duplication.

| Concern | Owner |
|---|---|
| Research specification and contracts | Markdown |
| Project configuration | **One YAML recipe** |
| Planning and reasoning | **Goose** |
| Project operations and execution | **Goose** |
| Host/security policy configuration | **Separate policy CLI** |
| VM isolation | Lima / QEMU |
| Instrumentation and telemetry | Declared tools in the recipe |
| Evidence and verification | Goose workflow + declared tooling |
| Durable state | Git |

Go code is allowed only for small, reusable helpers or policy-CLI implementation where it removes unsafe ad-hoc shell logic. It is **not** the project orchestrator.

## Full agentic workflow

A normal run is intended to look like:

```text
1. Goose reads Markdown + the project recipe
2. Goose discovers capabilities and dependencies
3. Goose resolves the requested workload/profile
4. Goose builds and reviews an execution plan
5. Policy CLI confirms the applicable host policy
6. Human approval is obtained for privileged/destructive actions
7. Goose provisions the disposable VM
8. Goose starts instrumentation and monitoring
9. Goose executes the workload in the VM
10. Goose collects and hashes evidence
11. Goose deterministically reduces evidence before LLM analysis where practical
12. Goose performs forensic analysis
13. Goose performs independent verification
14. Goose generates the experiment/SecOps report and token/cost summary
15. Goose records PASS / PARTIAL / FAIL / NOT_DEPLOYED honestly
16. Goose commits only recipe-permitted generated artifacts
```

The agent must never claim a component was exercised without runtime evidence.

## Project recipe

There is one authoritative project configuration entry point:

```text
recipes/goose/project.yaml
```

It selects workloads, VM profiles, instrumentation, monitoring, orchestration, routing, installation, reporting, safety requirements, and portability behavior. Supporting YAML files may remain as reusable data/catalogs, but **`project.yaml` is the single project configuration root**.

Example shape:

```yaml
version: 1
id: goose-project
harness: goose
workloads:
  directory: recipes/workloads/
vm_profiles:
  directory: recipes/lima/profiles/
instrumentation:
  directory: recipes/instrumentation/
monitoring:
  directory: recipes/agent-monitoring/
execution:
  operator: goose
policy:
  cli: policyctl
safety:
  disposable_vm_required: true
  host_credentials: deny
  host_mounts: deny
  preserve_evidence_before_destroy: true
```

The recipe is configuration, not a second programming language for an independent controller. Goose interprets it in context and reports unavailable capabilities rather than silently substituting them.

## Goose project operations

The conceptual project interface is:

```text
project discover
project validate
project preflight
project bootstrap
project plan
project review
project run <recipe/workload>
project collect
project forensic
project verify
project report
project tokens
project commit
```

These are **Goose project operations**, not a promise that a stock Goose binary exposes every name as a built-in CLI subcommand. They describe the agentic workflow and can be implemented as Goose prompts/tools/skills as appropriate.

## Policy CLI

The policy CLI is deliberately separate from Goose's project orchestration. It configures and checks host/security constraints such as:

```text
credentials       deny
host mounts       deny
privileged apply  require approval
network policy    explicit
VM isolation      required
```

Suggested interface:

```bash
policyctl check
policyctl show
policyctl set <policy> <value>
```

`policyctl` does not plan workloads, run experiments, collect evidence, or replace Goose.

## Installation and operation

The intended user experience is agent-first:

```text
1. Bootstrap only the minimum prerequisites.
2. Start Goose in the repository.
3. Give Goose the project recipe and requested goal.
4. Goose validates and preflights the environment.
5. Goose asks for approval where policy requires it.
6. Goose executes through the declared tools/backends.
7. Goose preserves evidence before destroying disposable resources.
```

A normal shell remains useful for recovery/debugging and for installing the small bootstrap prerequisites. It is not the normal project execution interface.

## Security model

- Untrusted workloads run only in disposable VMs.
- Host credentials are never exposed to workloads.
- Unrestricted host mounts are prohibited.
- Privileged or destructive operations require explicit approval.
- Agent output is treated as untrusted until independently verified.
- Raw telemetry is reduced deterministically before unnecessary LLM exposure.
- Evidence is preserved and hashed before VM destruction.
- Missing capabilities are reported as `NOT_DEPLOYED`; they are not silently replaced.
- Goose is an operator, **not the security boundary**. Isolation, policy, least privilege, and evidence controls provide the boundary.

## Repository layout

```text
01-*.md                    research contracts
AGENTS.md                  project/agent safety rules
recipes/goose/project.yaml single authoritative project recipe
recipes/                  reusable YAML catalogs and supporting data
scripts/                   compatibility/bootstrap helpers
cmd/                       small standalone utilities, including policy CLI
pkg/                       small reusable libraries
.github/                   CI validation
```

The project should evolve by improving the recipe and Goose capabilities before adding new orchestration code.

## Testing strategy

Testing is layered:

**L0 — contract test**

Goose reads the project and verifies that the recipe references are coherent.

**L1 — policy/preflight test**

Goose checks capabilities and the separate policy CLI without running an untrusted workload.

**L2 — disposable execution**

Goose provisions a real Lima/QEMU VM and runs a harmless workload.

**L3 — observed execution**

Goose adds syscall/network/filesystem instrumentation and agent monitoring.

**L4 — full agentic SecOps workflow**

Goose executes the complete lifecycle, then performs forensic analysis, independent verification, reporting, and controlled Git updates.

CI should cover deterministic contract/policy tests. Real VM and observability tests should run on explicitly provisioned research hosts.

## Status

The repository is **architecturally ready for Goose validation**, but it is not yet honest to call the complete L2–L4 workflow deployed. The current Go `labctl` bootstrap provides project validation/self-test; it should remain a small helper rather than grow into a competing orchestration plane.

The next implementation milestone is to consolidate the existing recipe references under the single `project.yaml` root, define the policy CLI contract, and validate the complete Goose-driven L0/L1 workflow before enabling real VM execution.

## Contributing

Changes should preserve the single-operator architecture. Prefer:

1. recipe changes for configuration;
2. Goose skills/tools/prompts for orchestration and execution behavior;
3. policy CLI changes for safety configuration;
4. small helpers only when deterministic functionality cannot safely live in Goose tooling.

Do not introduce a second project orchestrator, bypass policy, expose credentials, or claim untested components are deployed.

## AI disclaimer

AI agents, including Goose and any connected model, can make incorrect decisions or produce unsafe instructions. This project is for authorized security research and controlled experimentation. Human review, isolation, policy controls, and independent verification remain required for consequential operations.
