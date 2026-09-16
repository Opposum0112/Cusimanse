# Architecture

CAR is a harness-neutral control plane. Operators propose; CAR executes.

```text
┌── any harness ───────────────────────────────────┐
│  reasoner | HTTP client | human                         │
│  fills reasoningProposalSchema only                      │
└───────────────────────────────────────────────────┘
                    │
                    ▼
         CARGateway  or  RuntimeOrchestrator
                    │
     contract → resolve → policy → adapter → evidence
```

## Authority

| Concern | Operator / harness | CAR |
|---|---|---|
| Role + skill selection | ✓ reads `skills/registry.yaml` | registry is data |
| Proposal JSON | ✓ | validates |
| Contract / policy / adapter / VM / evidence | — | ✓ |
| Approval | — | ✓ |

```text
Operator:  THINK → PLAN → PROPOSE → ANALYZE
CAR:       CONTRACT → VALIDATE → RESOLVE → AUTHORIZE → EXECUTE
           → OBSERVE → PRESERVE → VERIFY → DESTROY
```

## Two attachments

1. **HTTP ABI** — `CARGateway` on loopback. Any process that can POST JSON.
2. **In-process reasoner** — `VercelAIReasoner` or `Reasoner`. Same schema. Proposals from `runtime.run` are still untrusted if the host re-submits them.

`createLab` requires at least one of these.

Roles are fields on skills, not a particular agent framework.
