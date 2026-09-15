# Cusimanse Researcher Guide

This guide is the practical path from a clean system to a complete controlled experiment. It does not change the README structure or replace the repository contracts, recipes, or policy sources of truth.

## 1. Clean-system bootstrap

Use a Linux host, macOS host, or Windows WSL2 environment supported by `recipes/host/security-research.yaml`. Start with Git and a network connection for installation dependencies.

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout goose-refactor

./scripts/install.sh
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

cusimanse doctor
```

`doctor` is the first deterministic health gate. If it fails, stop and fix the reported dependency or configuration before starting an experiment.

## 2. Understand the experiment before running it

The reference experiment is `npm-threat-001`. It is a local, deterministic fixture; it is not a public malicious package and must not be changed into one for routine testing.

Read the four source-of-truth artifacts together:

```bash
less contracts/npm-threat-001.md
less recipes/experiments/npm-threat-001.yaml
less recipes/npm-threat-001/recipe.yaml
less prompts/experiments/npm-threat-001.md
```

The contract defines authorization, scope and acceptance. The experiment YAML defines requirements. The Goose recipe is the native agent handoff. The shared prompt gives the agent its research objective without granting authority.

## 3. Stage 1 — validate the repository

```bash
cusimanse validate
```

This checks the required control-plane files, parses JSON/YAML control artifacts, validates policy and checks the repository for obsolete migration markers. Contract validation also confirms that every experiment contract has its matching experiment configuration, Goose recipe and shared prompt.

## 4. Stage 2 — preflight the host

```bash
cusimanse preflight
cusimanse tools list
cusimanse tools versions
```

Preflight checks the deterministic host/profile prerequisites. The tool inventory separates host control-plane tools from guest instrumentation.

## 5. Stage 3 — validate the Goose handoff

```bash
goose recipe validate recipes/npm-threat-001/recipe.yaml
goose recipe validate recipes/subrecipes/evidence-analysis.yaml
goose recipe validate recipes/subrecipes/verification.yaml
goose recipe validate recipes/subrecipes/report.yaml
```

Goose is the reference primary operator. Its `summon` extension provides delegation/orchestration capabilities; it does not override Cusimanse policy.

## 6. Stage 4 — resolve requirements into capabilities

```bash
cusimanse resolve npm-threat-001
cusimanse capability list
```

The resolver matches the experiment requirements against trusted profiles. No-match and ambiguous-match conditions fail closed.

## 7. Stage 5 — inspect and satisfy policy gates

```bash
cusimanse policy validate
cusimanse policy explain vm
cusimanse policy explain network
cusimanse policy check-all

# Researcher approval is an explicit action, not an agent decision.
cusimanse policy require vm --approved
```

The agent may request or explain an action, but only the Go capability API and declared policy can authorize execution. Public MCP, public gateways, credentials, unrestricted mounts and untrusted host execution remain denied.

## 8. Stage 6 — run the disposable experiment

Create a unique session identifier and run only after the required approval has been granted:

```bash
SESSION_ID="npm-threat-$(date +%Y%m%d-%H%M%S)"
cusimanse --approved run npm-threat-001 "$SESSION_ID"
```

The runtime lifecycle is:

```text
resolve
  → provision disposable Lima/QEMU compute
  → configure
  → start instrumentation
  → execute fixed workload
  → collect raw evidence
  → verify/hash
  → hand off to analysis/reporting
  → preserve
  → destroy disposable compute
```

The fixture is intentionally bounded to disposable compute and localhost behavior. Do not add credentials, host mounts, public package sources or external destinations.

## 9. Stage 7 — inspect evidence and observability

```bash
find "runs/$SESSION_ID" -maxdepth 3 -type f | sort
cat "runs/$SESSION_ID/evidence/index.yaml"
cat "runs/$SESSION_ID/verification/result.md"
cat "runs/$SESSION_ID/research-report/report.md"

cusimanse observability report "$SESSION_ID"
cusimanse policy audit
```

Evidence is the observation record. Model output is analysis and must not be treated as raw evidence. Independent verification must cite preserved evidence.

## 10. Stage 8 — verify preservation before destruction

A valid session contains the audit and provenance SHA-256 manifests and the required report/verification artifacts. Destruction is allowed only after preservation and verification requirements are satisfied.

For a control-plane-only rehearsal, the repository test suite exercises this lifecycle without requiring Lima:

```bash
cusimanse test
cusimanse integration-test
```

For an actual disposable VM smoke test, use:

```bash
CUSIMANSE_RUN_VM_TEST=1 cusimanse test
```

The optional VM test is deliberately separate because CI does not require a local hypervisor.

## 11. What the researcher owns vs. what the platform owns

| Researcher / agent | Cusimanse control plane |
|---|---|
| Research question and hypothesis | Policy and authority decisions |
| Contract and declared requirements | Capability resolution |
| Planning and specialist analysis | Trusted profiles and execution boundary |
| Agent delegation and reasoning | VM provisioning/configuration |
| Interpretation of observations | Instrumentation and evidence collection |
| Report narrative | Hashing, preservation and lifecycle guards |

An adapter such as OpenCode, Hermes, Antigravity or Pi is a prompt-handoff interface. It can plan, delegate and analyze with its native features, but it must invoke Cusimanse for capability execution.

## 12. Architecture in planes

```text
┌──────────────────────────────────────────────────────────────┐
│ RESEARCH / AGENT PLANE                                      │
│ Contract • Prompt • Goose/other agent • Roles • Skills      │
│ Hypothesis • Planning • Delegation • Analysis • Reporting   │
└──────────────────────────────┬───────────────────────────────┘
                               │ request / handoff
┌──────────────────────────────▼───────────────────────────────┐
│ CONTROL / POLICY PLANE                                      │
│ Go API • resolver • policy • approval • lifecycle • audit   │
│ Trusted profiles • experiment requirements • registries     │
└──────────────────────────────┬───────────────────────────────┘
                               │ authorized capability call
┌──────────────────────────────▼───────────────────────────────┐
│ CAPABILITY / EXECUTION PLANE                                │
│ Lima/QEMU • guest OS • fixed workload • instrumentation     │
│ Process • syscall • filesystem • network observation         │
└──────────────────────────────┬───────────────────────────────┘
                               │ evidence / telemetry
┌──────────────────────────────▼───────────────────────────────┐
│ EVIDENCE / OBSERVABILITY PLANE                              │
│ Raw evidence • hashes • provenance • verification • reports  │
│ Numbat • Aegis • Phoenix • OTel • ClawMetry                  │
└──────────────────────────────────────────────────────────────┘
```

### Shells and boundaries

- **Host shell:** bootstrap and compatibility only. It installs prerequisites and invokes unavoidable external tools such as Git, Lima, QEMU and Goose.
- **Agent shell:** the agent's native tool/command interface. It is not a security authority and must not bypass the Go capability API.
- **Go capability boundary:** the authoritative execution interface. Policy is evaluated here and decisions are audited.
- **Guest shell:** commands inside disposable compute. Workloads and collectors execute here rather than directly on the host.

The core rule is: **the agent decides what research to do; Cusimanse decides whether and how it may execute.**

## 13. Reference experiment variants

| Experiment | Researcher exercise |
|---|---|
| `go-install-001` | Observe Go installation and harmless local binary execution |
| `npm-install-001` | Observe pinned npm installation with lifecycle disabled |
| `npm-lifecycle-001` | Observe controlled local lifecycle execution |
| `npm-threat-001` | Observe the controlled adversarial-like local lifecycle fixture |

For each experiment, repeat the same gates: `validate → preflight → recipe validate → resolve → policy → approved run → evidence/observability → verification → preservation → destroy`.

## 14. Safety rule

These experiments are research fixtures, not authorization to access third-party systems. Keep execution disposable, local and bounded to the declared contract. Never add credentials, unrestricted mounts, public package execution or external destinations to the reference experiments.
