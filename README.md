# Cusimanse Agent Runtime

## What this branch is

`harness-neutral-runtime` is a lab for one security-research question at a time.

You write the question and the limits as files. Grok, Codex, Pi, Antigravity, or you may only **propose** the next observation. This runtime is the only thing that may create a VM, run the declared workload, collect evidence, or destroy the environment.

```text
You write the contract
        ↓
The lab freezes it
        ↓
An operator (Grok, Codex, Pi, Antigravity, or you) proposes a step
        ↓
The lab checks the contract, then acts
        ↓
The operator reads evidence and proposes again, or stops
```

The example question is **npm-install-day0**: what process, file, and network behavior appears when a pinned `npm install` runs on a disposable machine.

## Install

Need **Node.js 22 or newer** and git.

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout harness-neutral-runtime
npm install
```

## Open the lab

```bash
npm run lab:npm-install
```

Leave that terminal open until you see:

```text
npm-install-day0 lab is listening on http://127.0.0.1:8787
```

That process *is* the experiment. This starter lab checks the contract and records placeholder evidence. It does not boot a real VM. Use it to learn the loop, then point real adapters at disposable compute when you are ready.

## The LLM / operator layer

There is no special plugin for Grok, Codex, Pi, or Antigravity. Those tools are **operators**. An operator may only:

1. Read lab state and evidence.
2. Choose a skill from [`skills/registry.yaml`](skills/registry.yaml).
3. Send one proposal:

```json
{
  "proposal": {
    "intent": "watch the network during npm install",
    "capability": "network.observe",
    "parameters": { "interface": "eth0", "duration": 60 },
    "complete": false
  }
}
```

Give every operator this standing instruction:

> You are operating a Cusimanse lab. You do not have a shell. You do not install packages yourself. You only GET state/evidence and POST a proposal whose `capability` is on the contract allowlist. Never invent `command`, `shell`, or credentials. When the question is answered, POST `{ "intent": "done", "complete": true }`.

That is the whole LLM layer. The model thinks. The lab executes. Details and the same instruction as a paste block: [Operator LLM](docs/llm.md).

## Drive the lab from any harness

Keep `npm run lab:npm-install` running. In the harness, allow **only** HTTP to `127.0.0.1:8787` (or run the `curl` yourself if the tool cannot call localhost).

| What the operator does | Call |
|---|---|
| See where the experiment is | `GET /v1/research/npm-install-day0/state` |
| Ask for one observation | `POST /v1/research/npm-install-day0/proposals` |
| Read captured evidence | `GET /v1/research/npm-install-day0/evidence` |

**Grok** — paste the standing instruction plus the three URLs. Ask it for the next proposal. If it cannot reach your machine, it prints the JSON and you `curl` it.

**Codex** — same instruction. If it can run shell, restrict it to `curl` against `127.0.0.1:8787` only. Do not let it run `npm` or SSH.

**Pi** — same instruction and URLs. Treat replies as proposal JSON, then POST them.

**Antigravity** (or any other agent IDE) — add one tool: HTTP to those three paths. Do not add a terminal tool for this experiment.

**You, with no model:**

```bash
curl -s http://127.0.0.1:8787/v1/research/npm-install-day0/state

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

curl -s http://127.0.0.1:8787/v1/research/npm-install-day0/evidence
```

Suggested order of `capability` values:

1. `vm.create`
2. `workload.npm.install` with `{ "working_directory": "/workspace", "package_manager": "npm" }`
3. `network.observe`
4. `evidence.collect`
5. `{ "intent": "done", "complete": true }`

Off-allowlist example (`host.shell`) is denied. Look at `state` for `not_in_contract_allowlist`.

Another port: `CUSIMANSE_PORT=8788 npm run lab:npm-install`.

## Files for an experiment

Copy [`labs/npm-install-day0/`](labs/npm-install-day0/).

| File | What it is |
|---|---|
| `contract.yaml` | Question, non-goals, scope, allowed actions, planned steps, required evidence, stop and destroy |
| `policy.yaml` | Which of those actions may run without a human approval |
| `fixtures/package.json` | Pinned subject under test |

Do not give the operator a shell script or put keys in YAML. [Researcher workflow](docs/researcher-workflow.md).

Deny reasons: `not_in_contract_allowlist`, `scope_violation`, `destroy_blocked_until_evidence`, `max_proposals_exceeded`.

## Architecture

![How a proposal becomes evidence](docs/architecture.svg)

The operator proposes. The lab owns checks, adapters, evidence, and VM lifetime. [Architecture](docs/architecture.md).

## Limits

- One question per lab folder.
- The starter command uses placeholder adapters, not a real VM.
- Scope checks today cover `working_directory` against `scope.paths`.
- The local port has no login.
- Do not put credentials in YAML.
