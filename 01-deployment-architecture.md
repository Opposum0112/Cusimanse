# 01 — Deployment Architecture

## 1. Target state

```text
                           USER
                            |
                            v
                     +--------------+
                     | Orchestrator |
                     +------+-------+
                            |
                    Structured tasks
                            |
              +-------------+-------------+
              |                           |
        Agent/Harnesses               Blackboard
              |                           |
    +---------+---------+                 |
    |         |         |                 |
 Antigravity Grok    OpenCode             |
    |        Build       |                 |
    |         |         |                 |
    +---------+---------+-----------------+
                            |
                      HarnessRouter
                            |
                 +----------+----------+
                 |                     |
              LiteLLM              OmniRoute
                 |                     |
                 +----------+----------+
                            |
                      Model provider
                            |
                    MCP capability layer
                            |
                  +---------+---------+
                  |                   |
                Aegis              Numbat
             policy gate        visibility/events
                  |                   |
                  +---------+---------+
                            |
                       Lima / QEMU
                            |
                  Disposable Linux VM
                            |
            +---------------+----------------+
            |                                |
      Security tooling                 Experiment
            |                                |
            +---------------+----------------+
                            |
                       Evidence store
                            |
                Deterministic reduction
                            |
                   Forensics Agent
                            |
                Independent Verifier
                            |
                       Reporter
                            |
                       Git/GitHub
                            |
                    OTel/OpenInference
                            |
                         Phoenix
```

## 2. Planes

### Control plane
- Orchestrator
- Blackboard
- HarnessRouter
- Agent lifecycle
- Task queue
- Approval workflow

### Model plane
- LiteLLM OR OmniRoute
- Provider credentials
- Logical model aliases
- Fallbacks
- Budgets
- Token accounting

### Agent plane
- Antigravity CLI
- Grok Build
- OpenCode
- Goose
- Codex
- Custom agents and skills

### Capability/security plane
- MCP
- Aegis
- Numbat
- Hooks
- Permission rules

### Execution plane
- Lima
- QEMU
- Disposable VM profiles
- Docker OR Podman where containers are required

### Observation plane
- strace
- lsof
- bpftrace
- BCC
- Tetragon
- Sysdig
- tcpdump
- tshark
- Zeek
- Suricata
- mitmproxy

### Evidence/analysis plane
- JSONL/NDJSON
- PCAP
- logs
- process trees
- filesystem diffs
- network metadata
- deterministic reduction
- forensic analysis
- independent verification

### Knowledge plane
- Git
- GitHub
- experiment manifests
- reports
- skills registry
- versioned findings

### AI observability plane
- OpenTelemetry
- OpenInference
- Phoenix
- token/latency/cost/error telemetry

## 3. Harness neutrality

Antigravity CLI is the preferred general-purpose interactive harness for this deployment, but HarnessRouter remains the abstraction.

Recommended roles:

| Role | Preferred harness |
|---|---|
| Orchestration | Antigravity / dedicated orchestrator |
| Planning | Antigravity or Grok Build |
| Research | OpenCode / Goose |
| Building | Antigravity / Grok Build / OpenCode |
| Security review | Goose |
| VM execution | Controlled executor |
| Forensics | OpenCode |
| Independent verification | Codex or another independent harness/model |
| Reporting | Antigravity / Grok Build |
| Bootstrap | Grok Build or Antigravity |

## 4. Gateway rule

LiteLLM and OmniRoute are **alternatives**. Do not put one behind the other unless explicitly testing gateway composition.

## 5. Container rule

Docker and Podman are **alternatives** for the baseline. Docker is the simpler default; Podman can be selected for rootless/daemonless experiments.

## 6. Resource strategy

On 16 GB RAM:
- keep one heavy Lima VM active initially
- avoid running several heavyweight observability stacks simultaneously
- retain several GB of host headroom
- prefer hosted model APIs over large local-model inference
- collect evidence to disk and reduce it before sending it to an LLM

## 7. Authoritative architecture artifacts

See:
- `ai-security-lab-architecture.png`
- `ai-security-lab-experiment-workflow.png`
