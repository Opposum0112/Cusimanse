# 03 — Deployment Runbook

## Phase 0 — Repository bootstrap

Create a dedicated repository:

```text
ai-security-lab/
├── AGENTS.md
├── state.yaml
├── profiles.yaml
├── blackboard/
├── docs/
├── antigravity/
├── skills/
├── agents/
├── policies/
├── gateways/
├── vm/
├── experiments/
├── evidence/
├── reports/
├── manifests/
└── scripts/
```

Initialize Git before making major changes.

## Phase 1 — Host preflight

Run:

```bash
uname -a
uname -m
nproc
free -h
df -h
command -v qemu-system-x86_64
command -v limactl
```

Confirm adequate disk, memory and virtualization support.

Do not continue if the host is critically constrained.

## Phase 2 — Antigravity CLI

Official Linux/macOS installation:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

Then:

```bash
agy
```

Verify:

```bash
agy --help
```

Use the official Antigravity documentation for authentication and current CLI configuration.

Antigravity CLI supports workspace/global MCP configuration, plugins, skills, hooks and custom/background agents. Keep these extensions version-controlled where they are project-specific.

## Phase 3 — Other harnesses

Install only the harnesses required for the current milestone:

- Grok Build
- OpenCode
- Goose
- Codex

Record versions in `state.yaml`.

Do not install every optional harness before the baseline system is healthy.

## Phase 4 — Lima/QEMU

Install Lima and QEMU using the host's supported package mechanism.

Validate:

```bash
limactl --version
qemu-system-x86_64 --version
```

Create a minimal test VM.

Verify:
- boot
- shell access
- network
- shutdown
- deletion

Destroy the test VM after validation.

## Phase 5 — Container runtime

Select one:
- Docker
- Podman

Record the selected runtime in `state.yaml`.

Do not maintain two active runtimes without a test reason.

## Phase 6 — Model gateway

Deploy either:

```text
LiteLLM
```

or:

```text
OmniRoute
```

Define logical model aliases such as:

```yaml
cheap-code:
medium-code:
strong-reasoning:
premium-verifier:
long-context:
free:
```

Never commit credentials.

## Phase 7 — MCP

Create only narrowly scoped MCP servers.

Recommended tiers:

### Tier 1 — read-only
- filesystem read
- Git inspection
- evidence query
- jq/yq
- documentation search

### Tier 2 — development
- project file writes
- Git commits
- GitHub operations

### Tier 3 — VM
- Lima create/start/shell/stop/delete

### Tier 4 — privileged
- sudo
- host filesystem
- SSH
- cloud credentials
- network reconfiguration

Tier 4 must be approval-gated.

## Phase 8 — Aegis

Deploy Aegis between agent tool intent and sensitive capability execution.

Start with monitor/audit mode.

Verify that events contain enough context to reconstruct:
- actor
- task
- tool
- arguments
- policy
- decision

Only enable enforcement after monitor-mode behavior is understood.

## Phase 9 — Numbat

Deploy Numbat for agent security visibility.

Capture:
- tool calls
- commands
- sessions
- relevant runtime events
- security events

Start monitor-only.

## Phase 10 — OTel / OpenInference / Phoenix

Deploy the AI observability stack.

Capture:
- traces
- spans
- model
- provider
- tokens
- latency
- tool calls
- errors
- retries
- routing

Do not put secrets in telemetry.

## Phase 11 — Security instrumentation

Install and validate the observation tools incrementally.

Baseline sequence:

```text
process → syscall → filesystem → DNS → network → packet → protocol
```

Use deterministic tools to reduce data before LLM analysis.

## Phase 12 — Agent configuration

Install repository agents and skills from `antigravity/`, `agents/` and `skills/`.

The agent rules must enforce:
- no secret exposure
- no unrestricted host mounts
- no destructive host commands without approval
- evidence preservation
- VM-first execution
- Git checkpoints

## Phase 13 — First integration test

Run `experiments/go-install-001`.

Do not proceed to another experiment until the acceptance criteria pass or the failure is documented.

## Phase 14 — Git checkpoint

Commit the working baseline.

Suggested:

```text
chore(lab): establish multi-agent security research baseline
```
