# 05 — Multi-Agent Operating Model

## Design

Use structured delegation rather than an unrestricted swarm.

```text
Objective
  ↓
Planner
  ↓
Researcher
  ↓
Builder
  ↓
Security Reviewer
  ↓
HarnessRouter
  ↓
Executor
  ↓
Forensics
  ↓
Independent Verifier
  ↓
Reporter
  ↓
Archivist
```

## Agent responsibilities

### Planner
Defines objective, hypothesis, success criteria and evidence requirements.

### Researcher
Determines expected behavior and relevant instrumentation.

### Builder
Creates the experiment and disposable VM definition.

### Security Reviewer
Reviews permissions, network, mounts, credentials and destructive operations.

### Executor
Runs the approved experiment in the disposable VM.

### Forensics
Analyzes reduced evidence.

### Independent Verifier
Challenges claims using a different model/harness where possible.

### Reporter
Creates the research report and integration scorecard.

### Archivist
Commits the reproducibility package.

## HarnessRouter

HarnessRouter selects a harness according to:
- task type
- model availability
- context size
- security sensitivity
- cost
- latency
- required tools
- verification independence

Example:

```yaml
planner: antigravity
researcher: opencode
builder: grok-build
security-reviewer: goose
executor: controlled
forensics: opencode
verifier: codex
reporter: antigravity
```

## Model routing

Logical models:

```text
cheap-code
medium-code
strong-reasoning
premium-verifier
long-context
free
```

The token governor should consider:
- task complexity
- context size
- budget
- latency
- security sensitivity
- required reasoning quality

## Handoff contract

Agents communicate through structured artifacts, not copied conversation history.

Primary blackboard:

```text
blackboard/
├── state.json
├── plan.json
├── tasks.jsonl
├── findings.jsonl
├── decisions.jsonl
└── evidence-index.json
```

## Failure semantics

Every task should end in:
- completed
- blocked
- rejected
- failed
- partially-completed

Do not erase failure evidence.

## Independence

For high-confidence findings:

```text
Agent A → finding
Agent B → independent verification
```

The verifier should not inherit unverified conclusions as facts.
