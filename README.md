# Cusimanse Agent Runtime

Run one security-research experiment at a time, with a written contract that the lab cannot quietly outgrow.

You describe the question, what is out of scope, which observations are allowed, and when the disposable machine must be destroyed. An operator (a model, another research tool, or you) may only **ask** for the next step. The runtime is what is allowed to create a VM, run a declared workload, collect evidence, and tear the environment down.

```text
You write the contract
        ↓
The runtime freezes it
        ↓
An operator proposes the next observation
        ↓
The runtime checks the contract, then acts
        ↓
You read evidence and decide whether the question is answered
```

## Start with a lab folder

Do not start from a prompt. Copy [`labs/npm-install-day0/`](labs/npm-install-day0/).

| File | What it is |
|---|---|
| `contract.yaml` | The experiment: question, non-goals, allowed actions, planned steps, required evidence, stop and destroy rules |
| `policy.yaml` | Which of those actions are allowed without a human approval |
| `fixtures/package.json` | The pinned subject under test (here, `left-pad@1.3.0`) |

That lab asks: **what process, file, and network behavior appears during `npm install` of the fixture on a disposable VM?**

It does **not** ask the operator to exploit the package, keep the VM, or run shell on your workstation.

How to author the next lab: [Researcher workflow](docs/researcher-workflow.md). Contract fields: [Research contracts](docs/research-contracts.md).

## What you may put in a proposal

The operator speaks one shape only:

```json
{
  "intent": "watch the network during npm install",
  "capability": "network.observe",
  "parameters": { "interface": "eth0", "duration": 60 },
  "complete": false
}
```

- `capability` must be on the contract allowlist and must match a skill in [`skills/registry.yaml`](skills/registry.yaml).
- `complete: true` ends the conversation. It does not run anything.
- Extra fields such as `command` or `shell` are rejected.

Roles (threat researcher, detection engineer, reviewer) are labels on skills. They are not a particular agent product.

## How a run proceeds (npm-install example)

1. Provision the disposable VM (`vm.create`).
2. Install the pinned fixture in `/workspace` (`workload.npm.install`).
3. Observe the declared network (`network.observe`).
4. Collect process and log evidence (`evidence.collect`).
5. Stop, then destroy the VM once required evidence exists (`vm.destroy`).

Asking for `host.shell` or a path outside `/workspace` is denied. Typical deny reasons:

- `not_in_contract_allowlist` — capability was not written into the contract
- `scope_violation` — path or host is outside `scope`
- `destroy_blocked_until_evidence` — destroy was requested before required evidence exists
- `max_proposals_exceeded` — the contract budget is spent

## How an operator connects

The lab host exposes a local HTTP surface. Any research harness that can send JSON can drive it. Nothing in this runtime embeds a specific multi-agent product.

```text
POST /v1/research/{experimentId}/proposals
GET  /v1/research/{experimentId}/state
GET  /v1/research/{experimentId}/evidence
```

Listen on `127.0.0.1` only. This surface is unauthenticated; treat it as a local lab port.

You can also attach an in-process model that emits the same JSON. See [Operator LLM](docs/llm.md).

A host starts a lab with `createLab` from `@cusimanse/agent-runtime` and must attach one of those operators (HTTP gateway and/or in-process reasoner).

## Architecture

![How a proposal becomes evidence](docs/architecture.svg)

The operator thinks and proposes. The runtime owns contract checks, policy, adapters, evidence, and VM lifetime. Narrative: [Architecture](docs/architecture.md).

## Limits of this lab

- One experiment per contract. A new question is a new lab folder.
- Scope checks today cover working directory against `scope.paths`. Network and host limits still need adapter backing.
- Evidence kinds from adapters may need mapping if you rely on “destroy only after seal.”
- The local HTTP port has no login.
- Do not put API keys or credentials in YAML.
