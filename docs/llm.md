# How the operator LLM works

The lab does not “run Grok” or “run Codex.” It waits for a **proposal**. Whatever model you use is an operator sitting *outside* the lab.

```text
Grok / Codex / Pi / Antigravity / you
        reads state and evidence
        writes one proposal JSON
        ↓
http://127.0.0.1:8787
        ↓
lab: contract check → policy → adapter → evidence
```

The model never receives a tool that runs shell, `npm`, SSH, or Lima. If a harness can do those things, turn them off for this experiment.

## What the model is allowed to emit

```json
{
  "intent": "short research English",
  "capability": "network.observe",
  "parameters": { },
  "complete": false
}
```

- `capability` must be on that lab’s allowlist or the step is denied.
- `complete: true` means stop. No execution.
- `command`, `shell`, and extra keys are invalid.

## Standing instruction (paste into any harness)

```text
You operate the Cusimanse lab npm-install-day0.

Base URL: http://127.0.0.1:8787
GET  /v1/research/npm-install-day0/state
GET  /v1/research/npm-install-day0/evidence
POST /v1/research/npm-install-day0/proposals
     body: { "proposal": { "intent", "capability", "parameters", "complete" } }

Allowed capabilities only:
  vm.create
  workload.npm.install   parameters: { "working_directory": "/workspace", "package_manager": "npm" }
  network.observe        parameters: { "interface": "eth0", "duration": 60 }
  evidence.collect
  vm.destroy             only after required evidence exists

Do not run shell, npm, or SSH yourself.
Do not invent capabilities.
When the question is answered, POST complete: true.
```

## Per harness

**Grok** — paste the instruction. If Grok cannot call your localhost, ask it only for the next proposal JSON and POST it with `curl`.

**Codex** — paste the instruction. Allow `curl` to `127.0.0.1:8787` only. Disallow package installs and remote hosts.

**Pi** — paste the instruction. Treat each reply as proposal JSON and POST it.

**Antigravity** (and similar IDEs) — register three HTTP tools (GET state, GET evidence, POST proposal). Do not register a general terminal.

**Human** — same three `curl` calls; no model required.

## In-process model (optional)

If your host process already has a structured-output model, it can implement the same JSON in-process instead of HTTP. It still must not call adapters. The HTTP path above is the one to use with Grok, Codex, Pi, and Antigravity.
