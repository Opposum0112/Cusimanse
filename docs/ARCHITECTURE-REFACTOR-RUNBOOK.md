# Architecture Refactor Runtime Runbook

This runbook is the executable companion to the Architecture Refactor README. It separates **NORMAL SHELL** commands from **AGENT SHELL** prompts and explicitly distinguishes static validation from a real VM runtime test.

## 0. Preconditions

Run this on a Linux/macOS host with virtualization available. Use an isolated research machine for untrusted workloads. Never place API keys or provider credentials in Git.

## 1. Checkout

**[NORMAL SHELL]**

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout architecture-refactor
git status --short --branch
```

Confirm the output shows `architecture-refactor`.

## 2. Baseline validation

**[NORMAL SHELL]**

```bash
chmod +x scripts/prerequisites.sh scripts/agent-preflight.sh scripts/tests/validate-project.sh
./scripts/prerequisites.sh
./scripts/agent-preflight.sh
./policyctl validate
bash ./scripts/tests/validate-project.sh
```

If a required capability is missing, stop and record it as `NOT_DEPLOYED` rather than bypassing the contract.

## 3. Install the Architecture Refactor stack

**[NORMAL SHELL]**

```bash
CUSIMANSE_INSTALL_ARCH_REFACTOR=1 ./scripts/prerequisites.sh
bash ./scripts/tests/architecture-refactor.sh
```

This is an optional installation profile. It may install research utilities, Python dependencies for YAML/state/retrieval/observability and other architecture components according to the script and host package manager.

Check what is actually available:

```bash
command -v lima || true
command -v qemu-system-x86_64 || true
command -v python3 || true
command -v jq || true
command -v yq || true
command -v rg || true
python3 -c 'import yaml; print("PyYAML: OK")' 2>/dev/null || true
python3 -c 'import langgraph; print("LangGraph: OK")' 2>/dev/null || true
```

Do not interpret a missing optional tool as a successful deployment.

## 4. Choose exactly one primary agent

**[NORMAL SHELL]**

Prime Agent:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=prime-agent
prime-agent --help
```

Hermes:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=hermes
hermes --help
```

Existing adapter compatibility example:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=goose
goose --help
```

The `--help` check verifies the local CLI. Provider/model authentication must be configured according to that agent's own documentation. Do not put credentials in YAML or the repository.

## 5. Host-side policy check

**[NORMAL SHELL]**

```bash
./policyctl validate
```

**Do not ask the agent to run `policyctl`.** `policyctl` is intentionally outside the agent control plane.

## 6. Start the primary agent

**[AGENT SHELL]**

Prime Agent:

```bash
prime-agent
```

Hermes:

```bash
hermes
```

Use the agent's locally verified headless mode only if `--help` confirms it. Do not invent command-line flags.

## 7. Primary Cusimanse prompt

**[AGENT PROMPT]**

Paste the following into the selected agent:

```text
Act as the primary operator for one Cusimanse security-research case.

First read:
  recipes/agents/self-learning-primary.yaml
  recipes/campaigns/security-research-learning.yaml
  recipes/workflows/security-research-taskflow.yaml
  recipes/orchestration/langgraph.yaml
  recipes/learning/skill-promotion.yaml

Follow this lifecycle exactly:
  Discover -> Validate -> Retrieve -> Plan -> Review -> Approve ->
  Provision VM -> Instrument -> Execute -> Collect -> Analyze ->
  Verify -> Learn -> Promote -> Preserve -> Destroy

Execution rules:
- The disposable Lima/QEMU VM is the execution boundary for the workload.
- Do not treat the LLM, prompt, skill, MCP, vector database, Taskflow or LangGraph as a security boundary.
- Do not invoke policyctl. It is host-side and outside the agent control plane.
- Do not expose host credentials to the workload or learned skills.
- Retrieve skills only after checking capability metadata, risk tier, tool requirements and validation state.
- Retrieval ranking never grants permission to execute a capability.
- Preserve raw evidence, telemetry, audit records, reductions, verification results and hashes before destroying the VM.
- A new learned procedure must first be CANDIDATE.
- Promotion requires the configured replay, distinct-artifact, independent-verification, provenance, capability and human-approval gates.
- If a dependency or capability is unavailable, report NOT_DEPLOYED.
- Never claim PASS without runtime evidence.
- At completion report: case ID, campaign, current state, commands/tools used, VM state, evidence paths, verification result, skill state and failed gates.
```

## 8. First integration test: existing Go experiment

**[AGENT PROMPT]**

```text
Run the existing experiments/go-install-001 reference experiment using the new Architecture Refactor workflow while preserving compatibility with the existing Cusimanse architecture.

Use the campaign and Taskflow-style workflow, maintain case state according to the orchestration contract, operate the workload inside the disposable Lima/QEMU VM, collect telemetry and evidence, perform independent verification, preserve all artifacts and only then destroy the disposable VM.

Do not modify policyctl or bypass approval controls.

At the end, report PASS, PARTIAL, FAIL or NOT_DEPLOYED according to evidence. PASS requires actual runtime evidence.
```

## 9. Observe the result

**[NORMAL SHELL / OBSERVE]**

```bash
find evidence blackboard experiments/go-install-001 -maxdepth 4 -type f -print 2>/dev/null
find runs -maxdepth 4 -type f -print 2>/dev/null
```

Look for:

```text
manifest
raw evidence
telemetry
execution/audit records
reductions
forensics
verification
report
hashes
```

The exact output layout depends on the existing experiment implementation. Do not manufacture missing evidence.

## 10. Test skill creation

Use a completed case containing a procedure that is genuinely reusable.

**[AGENT PROMPT]**

```text
From the completed case, identify one reusable research procedure that is supported by evidence.

Create a CANDIDATE skill package under the configured skill area containing:
- SKILL.md
- deterministic scripts where appropriate
- references
- evaluation cases
- capability/risk metadata
- provenance linking the candidate to the source artifact, case and execution

Do not promote it.
Do not overwrite the original evidence.
Record why the procedure is reusable and what its known limitations are.
```

Expected state:

```text
CANDIDATE
```

## 11. Retrieve and replay the candidate

Use a **different artifact** or replay fixture.

**[AGENT PROMPT]**

```text
Retrieve the CANDIDATE skill using its description and capability metadata.

Before execution, verify that its required tools are available and that its risk tier is allowed by the campaign.

Replay the candidate against the second, distinct artifact without modifying the original evidence.
Record the exact skill version, input artifact identity, commands/tool calls, outputs and result.

Classify the result as PASS, PARTIAL, FAIL or INCONCLUSIVE.
Do not promote the skill based on retrieval score or LLM confidence.
```

## 12. Independent verification

**[AGENT PROMPT]**

```text
Independently verify the replay result using a method that does not simply repeat the same inference path.

Compare the expected and observed result, preserve verification evidence and record the verification method and outcome.

If the result is not independently supported, leave the skill as CANDIDATE or FAIL it. Do not promote it.
```

## 13. Promotion gate

The intended promotion path is:

```text
Evidence
  -> CANDIDATE
  -> replay
  -> distinct artifact
  -> independent verification
  -> provenance/capability checks
  -> human approval
  -> VALIDATED
  -> retrieval index
```

**[HUMAN APPROVAL]**

Review the candidate's evidence, evaluation results, risk/capability manifest and provenance before approving promotion.

**[AGENT PROMPT after approval]**

```text
The human approval gate has passed. Promote only the exact reviewed skill version.
Record the approval and promotion event, preserve provenance and evaluation results, and index the validated skill for future retrieval.
Do not change the reviewed executable content during promotion.
```

## 14. Adapter equivalence test

Repeat the same campaign with another primary agent.

**[NORMAL SHELL]**

```bash
export CUSIMANSE_PRIMARY_ADAPTER=hermes
hermes --help
hermes
```

Then paste the **same primary Cusimanse prompt** from Section 7.

For Prime Agent:

```bash
export CUSIMANSE_PRIMARY_ADAPTER=prime-agent
prime-agent --help
prime-agent
```

The purpose is not to make the agents behave identically. It is to verify that the **Cusimanse research contract, evidence requirements and security boundary remain unchanged while the operator changes**.

## 15. Final validation

**[NORMAL SHELL]**

```bash
./policyctl validate
bash ./scripts/tests/validate-project.sh
bash ./scripts/tests/architecture-refactor.sh
git status --short --branch
```

Expected branch:

```text
## architecture-refactor
```

No merge into `main` is part of this runbook.

## 16. Runtime acceptance checklist

A real runtime test is complete only when all applicable items have evidence:

- [ ] architecture validation passed
- [ ] selected primary agent CLI verified
- [ ] provider/model configuration verified locally
- [ ] Lima/QEMU VM actually provisioned
- [ ] workload executed inside the VM
- [ ] instrumentation/telemetry collected
- [ ] raw evidence preserved
- [ ] verification performed independently
- [ ] VM destroyed only after evidence preservation
- [ ] candidate skill has provenance
- [ ] candidate replayed on a distinct artifact
- [ ] promotion gates evaluated
- [ ] human approval recorded for promotion
- [ ] final project validation passed

A static CI success does **not** check the VM boxes above.

## 17. Troubleshooting state meanings

| State | Use when |
|---|---|
| `PASS` | Runtime behavior was actually demonstrated and evidence is preserved |
| `PARTIAL` | Some stages worked but required coverage/evidence is incomplete |
| `FAIL` | A tested contract or expected behavior failed |
| `NOT_DEPLOYED` | The dependency/provider/capability is unavailable or intentionally disabled |
| `CANDIDATE` | A reusable skill exists but has not passed promotion gates |
| `VALIDATED` | Required replay, verification, provenance and approval gates passed |

Never convert `NOT_DEPLOYED` into `PASS` merely because a YAML entry exists.
