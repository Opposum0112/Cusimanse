# Architecture

![How a proposal becomes evidence](architecture.svg)

A researcher writes a contract. An operator (any tool that can emit the proposal JSON, or a person) asks for the next observation. Cusimanse Agent Runtime is the only component that may change the lab.

```text
Lab folder          skills/registry.yaml
contract.yaml       role → skill → capability name
        ↓
Frozen contract (hash)
        ↓
Operator proposal { intent, capability, parameters, complete }
        ↓
Allowlist / scope / stop / destroy checks
        ↓
Capability exists? → policy / approval → adapter on disposable compute
        ↓
Evidence + state   (the operator may only read these)
```

## Who may do what

| | Operator (model, harness, or human) | Runtime |
|---|---|---|
| Choose the next skill / write a proposal | yes | no |
| Change the contract mid-run | no | no |
| Approve a gated action | no | yes |
| Create or destroy the VM | no | yes |
| Run `npm install` or capture packets | no | yes, via a registered adapter |
| Read state and evidence | yes | yes |

```text
Operator   think → plan → propose → read evidence
Runtime    check contract → authorize → execute → record → destroy
```

## Connecting an operator

- Local HTTP: propose / state / evidence on `127.0.0.1`.
- In-process model: same JSON schema, no extra tools.

The lab host must attach at least one of those before a run starts.

Roles live on skills in `skills/registry.yaml`, not inside a particular agent product.
