# Operator ABI

Versioned HTTP surface for every harness.

```text
POST /v1/research/{experimentId}/proposals
GET  /v1/research/{experimentId}/state
GET  /v1/research/{experimentId}/evidence
```

Payload must parse as `reasoningProposalSchema`. Host `127.0.0.1`. No auth in this prototype.

In-process equivalent: `OperatorPort` in `src/gateway/contracts.ts`.
