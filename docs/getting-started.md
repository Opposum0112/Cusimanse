# Getting started

## 1. Copy a lab

Use [`labs/npm-install-day0/`](../labs/npm-install-day0/) as the first experiment. It already has a contract, a policy file, and a pinned `package.json` fixture.

Read [researcher-workflow.md](researcher-workflow.md) before you add files.

## 2. Freeze the contract

The host compiles `contract.yaml`. A hash is stored with the experiment so later proposals are checked against that freeze, not against a prompt.

## 3. Attach an operator and open the lab port

The host starts the runtime with either:

- a local HTTP port (`127.0.0.1`) that accepts proposal JSON, or
- an in-process model that emits the same JSON.

Point your operator at:

```text
POST /v1/research/npm-install-day0/proposals
GET  /v1/research/npm-install-day0/state
GET  /v1/research/npm-install-day0/evidence
```

## 4. Drive the question

Propose only allowlisted capabilities. Read evidence. Stop when the contract is satisfied. Destroy the VM after the required evidence exists.

Details for models: [llm.md](llm.md). Contract language: [research-contracts.md](research-contracts.md).
