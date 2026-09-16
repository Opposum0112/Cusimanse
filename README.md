# Cusimanse Agent Runtime

## What this branch is

`harness-neutral-runtime` is the researcher-facing lab runtime. You write one experiment as files. A model, another tool, or you may only **propose** the next observation. This runtime is what is allowed to act inside the lab.

It is not a chatbot, and it is not tied to one agent product. Roles and skills are names in YAML. Any operator that can send a small JSON proposal can drive the same experiment.

```text
You write the contract
        ↓
The runtime freezes it
        ↓
You or a model propose the next step
        ↓
The runtime checks the contract, then acts
        ↓
You read evidence and stop when the question is answered
```

The worked example is **npm-install-day0**: what process, file, and network behavior appears when a pinned `npm install` runs on a disposable machine.

## Install

You need **Node.js 22 or newer** and git.

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout harness-neutral-runtime
npm install
```

Check that the tree is healthy (optional but recommended the first time):

```bash
npm run typecheck
npm test
```

## Run the example lab

From the repository root:

```bash
npm run lab:npm-install
```

Leave that terminal open. You should see:

```text
npm-install-day0 lab is listening on http://127.0.0.1:8787
```

That process is the lab. This starter host uses **stub adapters**: it enforces the contract and records fake evidence URIs. It does not boot Lima or run a real `npm install`. Use it to learn the proposal loop. Wire real adapters when you run on disposable compute.

### See the current state

In a second terminal:

```bash
curl -s http://127.0.0.1:8787/v1/research/npm-install-day0/state | python3 -m json.tool
```

### Propose an allowed step

```bash
curl -s -X POST http://127.0.0.1:8787/v1/research/npm-install-day0/proposals \
  -H 'content-type: application/json' \
  -d '{
    "proposal": {
      "intent": "watch the network during npm install",
      "capability": "network.observe",
      "parameters": { "interface": "eth0", "duration": 60 },
      "complete": false
    }
  }'
```

Allowed names on this lab: `vm.create`, `workload.npm.install`, `network.observe`, `evidence.collect`, `vm.destroy`.

A sensible order:

1. `vm.create`
2. `workload.npm.install` with `{ "working_directory": "/workspace", "package_manager": "npm" }`
3. `network.observe`
4. `evidence.collect`
5. `{ "intent": "done", "complete": true }` to stop without executing

### Read evidence

```bash
curl -s http://127.0.0.1:8787/v1/research/npm-install-day0/evidence | python3 -m json.tool
```

### See a denial

```bash
curl -s -X POST http://127.0.0.1:8787/v1/research/npm-install-day0/proposals \
  -H 'content-type: application/json' \
  -d '{
    "proposal": {
      "intent": "open a shell",
      "capability": "host.shell",
      "parameters": {},
      "complete": false
    }
  }'
```

Then look at `state`. You should see `not_in_contract_allowlist`. Nothing runs.

Change the port with `CUSIMANSE_PORT=8788 npm run lab:npm-install`.

## Files you write for an experiment

Copy [`labs/npm-install-day0/`](labs/npm-install-day0/).

| File | What it is |
|---|---|
| `contract.yaml` | Question, non-goals, scope, allowed actions, planned steps, required evidence, stop and destroy |
| `policy.yaml` | Which of those actions may run without a human approval |
| `fixtures/package.json` | Pinned subject under test (`left-pad@1.3.0`) |

Do not add a shell script for the model, API keys in YAML, or extra tools. Authoring guide: [Researcher workflow](docs/researcher-workflow.md).

## What a proposal may contain

```json
{
  "intent": "watch the network during npm install",
  "capability": "network.observe",
  "parameters": { "interface": "eth0", "duration": 60 },
  "complete": false
}
```

`capability` must be on the contract allowlist. `complete: true` ends the run and does not execute. Fields such as `command` are rejected.

Roles (threat researcher, detection engineer) are labels on [`skills/registry.yaml`](skills/registry.yaml). They are not a particular vendor product.

Deny reasons you will see:

- `not_in_contract_allowlist`
- `scope_violation`
- `destroy_blocked_until_evidence`
- `max_proposals_exceeded`

## How another tool attaches

The lab port is the whole integration:

```text
POST /v1/research/npm-install-day0/proposals
GET  /v1/research/npm-install-day0/state
GET  /v1/research/npm-install-day0/evidence
```

Bind to `127.0.0.1`. There is no login on this prototype. A model that emits the same JSON can be attached in-process; see [Operator LLM](docs/llm.md).

## Architecture

![How a proposal becomes evidence](docs/architecture.svg)

The operator proposes. The runtime owns contract checks, policy, adapters, evidence, and VM lifetime. [Architecture](docs/architecture.md).

## Limits

- One question per lab folder.
- The command above uses stub adapters, not a real VM.
- Scope checks today cover `working_directory` against `scope.paths`.
- The local port is unauthenticated.
- Do not put credentials in YAML.
