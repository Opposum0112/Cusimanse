# Runtime Installation, Integration and Usage

This guide describes the Architecture Refactor branch. It is additive and does not alter `main`.

## 1. Host prerequisites

Baseline:

- Linux or macOS
- Git, Bash, curl, Python 3, Go
- QEMU and Lima
- Goose for the existing reference path
- sudo on Linux or Homebrew on macOS when automated installation is requested

Optional architecture components can be installed with:

```bash
CUSIMANSE_INSTALL_ARCH_REFACTOR=1 ./scripts/prerequisites.sh
```

This adds common analysis/transform tools, SQLite, observability and Python packages used by the optional stateful-learning prototype. Prime Agent and Hermes are reported separately because their installers/providers may be user-managed and must not receive credentials from the repository.

## 2. Checkout

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout architecture-refactor
```

Never run the refactor worktree commands against `main` while validating this branch.

## 3. Install

```bash
./scripts/prerequisites.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

Then optionally install the refactor toolset:

```bash
CUSIMANSE_INSTALL_ARCH_REFACTOR=1 ./scripts/prerequisites.sh
```

## 4. Validate the architecture

```bash
bash ./scripts/tests/architecture-refactor.sh
```

The integration script checks file/contract presence, YAML parsing, shell syntax, Go validation, skill frontmatter and that the existing `go-install-001` and Goose recipe remain referenced. It does not claim a VM run unless Lima actually boots and evidence is produced.

## 5. Select a primary adapter

The existing adapter mechanism remains the compatibility layer. Examples:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=goose
export CUSIMANSE_PRIMARY_ADAPTER=prime-agent
export CUSIMANSE_PRIMARY_ADAPTER=hermes
```

Run the adapter preflight before execution. An adapter is `NOT_DEPLOYED` until its CLI, provider configuration and adapter contract are verified.

## 6. Runtime workflow

```text
Discover
  -> Validate contracts
  -> Load campaign recipe
  -> Restore/create LangGraph case state
  -> Retrieve candidate skills
  -> Plan
  -> Review
  -> Approval gate
  -> Provision Lima/QEMU VM
  -> Instrument
  -> Execute workload
  -> Collect evidence
  -> Reduce/forensics
  -> Independent verification
  -> Generate report
  -> Preserve and hash evidence
  -> Evaluate reusable capability
  -> Replay candidate skill
  -> Promote only after policy/verification/approval
  -> Destroy disposable VM
```

`policyctl` is intentionally outside this agent workflow. It is a host-side policy/configuration and token-observability utility. The agent must not use it as a sandbox or controller.

## 7. Campaign recipe

A campaign should describe semantics rather than embed host implementation details. Example:

```yaml
id: hunt-lolbin-execution
version: 1.0
hypothesis: Living-off-the-land execution via signed binaries
roles: [hunter, soc_analyst, detection_engineer, tool_integrator]
inputs: [prefetch, amcache]
gates:
  human_approve: promote_skill
promotion:
  minimum_validated_cases: 2
  minimum_distinct_artifacts: 2
  require_replay: true
  require_independent_verification: true
  require_human_approval: true
```

## 8. LangGraph case state

Keep runtime state separate from evidence:

```text
case_id
campaign_id
current_node
current_hypothesis
retrieved_skills
tool_traces
pending_hitl
execution_ids
```

Checkpoints make a workflow resumable. The durable evidence store remains the source of truth for artifacts, provenance and verification.

## 9. Self-learning workflow

```text
Task
  -> retrieve top-k skills
  -> inspect capability manifests
  -> select/combine capability
  -> execute under VM boundary
  -> collect result
  -> evaluate
       |-- fail -> refine candidate
       `-- pass -> replay on distinct sample
                    -> independent verification
                    -> human approval
                    -> publish versioned SKILL.md
                    -> index description/tags
```

Never execute an unreviewed generated skill on the host merely because retrieval ranked it highly.

## 10. Prime Agent adapter

Prime Agent is treated as a self-improving primary operator. Cusimanse does not assume that Prime's own memory, RLM/subagent behavior or generated commands constitute evidence.

Adapter responsibilities:

```text
Cusimanse contract
   -> Prime Agent session
   -> retrieve candidate skills
   -> operate approved experiment
   -> capture traces/evidence
   -> emit skill candidate
   -> Cusimanse replay/verification
   -> promotion gate
```

Install and CLI syntax must be verified with the current Prime Agent documentation/installer on the target host. Do not bake provider keys into recipes.

## 11. Hermes adapter

Hermes is similarly treated as a self-improving primary operator. Its native skills/memory can accelerate repeated work, while Cusimanse owns provenance, evidence and promotion.

```text
Cusimanse case
   -> Hermes session
   -> native capability retrieval/memory
   -> approved VM operation
   -> evidence
   -> candidate skill
   -> replay + independent verification
   -> promotion
```

Verify the installed CLI and provider setup locally before marking the adapter `PASS`.

## 12. Existing architecture integration test

The compatibility test has two tracks:

### Static integration

- shared experiment contracts still parse
- existing Goose project recipe is present
- `go-install-001` remains intact
- prerequisite and validation scripts parse
- new recipes/contracts/registries parse
- skill packages have valid frontmatter
- MCP registry has no unscoped public exposure
- Go and shell checks pass

### Runtime integration

When a host has the required dependencies and a configured agent:

1. run `policyctl validate` from the normal shell
2. launch the selected primary agent
3. load `recipes/learning/security-research-learning.yaml`
4. execute the campaign against a disposable VM
5. collect evidence under the run directory
6. run the skill evaluation harness
7. preserve hashes before destroy
8. report `PASS`, `PARTIAL`, `FAIL` or `NOT_DEPLOYED`

A static test never upgrades a runtime capability to `PASS`.

## 13. Troubleshooting

- Missing optional tools: run the optional prerequisite flag and rerun validation.
- Missing agent CLI/provider: mark that adapter `NOT_DEPLOYED`; do not substitute another adapter silently.
- Lima unavailable: stop before VM execution.
- Missing evidence: the experiment is not `PASS`.
- Skill replay failure: keep the candidate unpromoted and retain the failure evidence.
- Policy mismatch: stop and resolve the host/VM configuration outside the agent control plane.