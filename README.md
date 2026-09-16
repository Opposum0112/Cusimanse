# Cusimanse Agent Runtime (CAR)

CAR is a **research-contract runtime** for agent-operated security labs.

You write a YAML contract that freezes one experiment. An LLM — either CAR's built-in reasoner or an external CrewAI crew — may **propose** the next observation. CAR is the only component that validates, authorizes, executes, records evidence, and destroys disposable compute.

```text
Human writes / reviews the contract
        ↓
CAR compiles and freezes it          ←  law of the experiment
        ↓
Operator LLM proposes {intent, capability, parameters}
        ↓
CAR: contract check → capability → policy → adapter → evidence
        ↓
Operator reads state/evidence and proposes again
        ↓
Stop condition or human ends the run
        ↓
CAR seals what it has and the host destroys the VM
```

## What this is — and is not

**This branch is**

- a TypeScript control plane that compiles a research contract into IR
- a default-deny policy + approval state machine
- adapters for declared capabilities (Lima / workloads)
- an optional in-process **proposal-only** reasoner (`src/llm`)
- an optional CrewAI **operator** that can only POST proposals and GET state/evidence

**This branch is not**

- a new multi-agent framework
- a shell tool for CrewAI or for the built-in reasoner
- a multi-tenant hosted service
- an approval authority that the LLM can grant itself

If a change gives any LLM a second execution path (subprocess, raw VM API, credentials), it is out of scope.

## Authority split

| Layer | May do | May not do |
|---|---|---|
| Built-in reasoner or CrewAI | reason, pick a skill, write a proposal, read evidence | execute, approve, destroy on its own, change policy |
| Skill registry | name research vocabulary | grant power |
| Contract (`recipes/*.yaml`) | declare legal capabilities, scope, evidence, stop rules | contain shell |
| CAR runtime | authorize and run adapters | trust a proposal as a command |

```text
Operator LLM:  THINK → PLAN → PROPOSE → ANALYZE
CAR:           CONTRACT → VALIDATE → RESOLVE → AUTHORIZE → EXECUTE
               → OBSERVE → PRESERVE → VERIFY → DESTROY
```

## LLM and reasoning layer

CAR has **no required model**. A contract can run with zero LLM. When you do attach a model, you choose one operator:

| | Setup A — built-in reasoner | Setup B — CrewAI as operator |
|---|---|---|
| Code | `VercelAIReasoner` in `src/llm` | Python `Agent` + `CAR_TOOLS` |
| Model config | Vercel AI SDK 7 `LanguageModel` | CrewAI `LLM(model=...)` |
| How it reaches CAR | Host injects `reasoner` into `RuntimeOrchestrator` | HTTP to `CARGateway` |
| Auto-executes? | **No.** Returns `result.proposals` for the host to re-submit | **No.** Gateway still runs contract + policy |
| Multi-agent roles | No | Yes |

Same proposal shape for both:

```ts
{ intent: string; capability?: string; parameters?: object; complete: boolean }
```

`capability` is required to execute. `complete: true` stops without execution. Extra keys like `command` are rejected.

Do not enable A and B on the same experiment unless the host decides which proposals count toward `stop_when.max_proposals`.

Configure A or B: **[`docs/llm.md`](docs/llm.md)**. Architecture: **[`docs/crewai-architecture.md`](docs/crewai-architecture.md)**.

### Setup A — built-in reasoner (short)

```ts
import { VercelAIReasoner } from "./src/llm/index.js";
import { RuntimeOrchestrator } from "./src/runtime/index.js";

const reasoner = new VercelAIReasoner({
  model: languageModel, // AI SDK 7 provider of your choice
  system: "Proposal-only CAR reasoner. Stay on the frozen allowlist. Never emit shell.",
});

const runtime = new RuntimeOrchestrator({
  capabilities, policy, approvals, operations, adapters,
  reasoner, // omit for no in-process model
});
```

After `runtime.run`, inspect `result.proposals` and submit anything you accept as a new intent. The reasoner does not call adapters.

### Setup B — CrewAI as operator (short)

CrewAI is outside CAR. Each agent gets **only** the three CAR tools and its own `LLM`.

```python
from crewai import Agent, LLM
from integrations.crewai.cusimanse_tools import CAR_TOOLS

researcher = Agent(
    role="Threat Researcher",
    goal="Investigate the frozen research question using only CAR skills",
    llm=LLM(model="gpt-4.1"),
    tools=CAR_TOOLS,
    allow_delegation=False,
)
```

Set `CUSIMANSE_CAR_URL=http://127.0.0.1:8787`. Do not add shell tools. Role/skill mapping: [`skills/crewai/README.md`](skills/crewai/README.md).

## The four objects

1. **Contract** — frozen experiment file. Compiled to `CusimanseIR.contract` plus a SHA-256 `hash`.
2. **Skill** — framework-neutral name in `skills/registry.yaml` pointing at a capability.
3. **Proposal** — JSON the operator submits. Data, not a command. Must include `capability` to execute.
4. **Capability** — registered operation such as `network.observe`. Reaches an adapter only after the contract and policy both allow it.

Details and deny codes: [`docs/research-contracts.md`](docs/research-contracts.md).

## `crewai` branch wiring

```text
Setup A: VercelAIReasoner ──► result.proposals ─ host re-submits ─┐
                                                     │
Setup B: CrewAI crew → CAR_TOOLS → HTTP proposal ────────────────┴→ CAR Gateway
                                                                      ↓
                                                    Contract → Resolve → Policy → Adapter
```

## Contract shape

Example (abridged from `recipes/examples/npm-install.yaml`):

```yaml
api_version: v1
kind: ExperimentRecipe
experiment_id: npm-install-example
contract_version: "0.2"
research_question:
  id: rq-npm-install
  question: What observable behavior occurs during npm install?
  non_goals:
    - Do not persist the VM after evidence is sealed.
allowed_capabilities: [vm.create, vm.destroy, workload.npm.install, evidence.collect, network.observe]
scope:
  hosts: [disposable-vm]
  paths: [/workspace]
  networks: [declared-test-network]
intents:
  - id: provision-research-vm
    capability: vm.create
    depends_on: []
  - id: run-npm-install
    capability: workload.npm.install
    parameters: { working_directory: /workspace, package_manager: npm }
    depends_on: [provision-research-vm]
evidence_required:
  - { type: process, produced_by: evidence.collect }
  - { type: network, produced_by: network.observe }
stop_when:
  all_evidence_required: true
  max_proposals: 20
destroy:
  capability: vm.destroy
  require_evidence_sealed: true
```

If `allowed_capabilities` is omitted, CAR does **not** apply an extra allowlist. Set it when you want the freeze to bind later operator proposals, not only the static `intents` list.

Contract deny codes (before policy):

- `not_in_contract_allowlist`
- `scope_violation` (`working_directory` outside `scope.paths`)
- `destroy_blocked_until_evidence`
- `max_proposals_exceeded`

## Repository layout

```text
src/
├─ compiler/          recipe → IR + contract.hash
├─ ir/                normalized contract + intents
├─ contract/          allowlist / scope / seal / stop checks
├─ planner/           depends_on order
├─ capabilities/      name registry (no execution)
├─ policy/            allow | approval-required | deny
├─ operations/        operation lifecycle
├─ adapters/          Lima + workloads
├─ evidence/          hashed artifacts
├─ state/             events + phase
├─ llm/               proposal schema + optional VercelAIReasoner
├─ runtime/           orchestrator + disposable workflow
└─ integrations/crewai/  HTTP gateway for the CrewAI operator

integrations/crewai/     Python CAR_TOOLS (POST/GET only)
skills/                  framework-neutral vocabulary
recipes/examples/        contracts
docs/llm.md              how to configure A vs B
docs/research-contracts.md
```

## Install

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout crewai
npm install
npm run typecheck
npm test
```

Node.js 22+ is required. A model provider SDK is only needed if you use Setup A. CrewAI is only needed for Setup B.

CrewAI operator (optional, isolated venv):

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r integrations/crewai/requirements.txt
export CUSIMANSE_CAR_URL=http://127.0.0.1:8787
```

## Running the CrewAI operator

The gateway is a **library**. A host process constructs `RuntimeOrchestrator` (with or without a built-in reasoner), compiles a contract, registers the session, and listens on loopback.

```ts
import { CARGateway } from "./src/integrations/crewai/server.js";

const runtime = /* RuntimeOrchestrator; pass reasoner only for Setup A */;
const gateway = new CARGateway(runtime);
gateway.register({ ir: compiledContract, state: initialResearchState });
gateway.listen({ host: "127.0.0.1", port: 8787 });
```

The prototype gateway has **no authentication** and keeps sessions in memory. Do not expose it on a public interface.

`CAR_TOOLS` is only `car_submit_research_proposal`, `car_get_research_state`, and `car_get_evidence`.

## Gateway API

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/v1/research/{experimentId}/proposals` | Submit one typed proposal |
| `GET` | `/v1/research/{experimentId}/state` | Read CAR state |
| `GET` | `/v1/research/{experimentId}/evidence` | Read evidence |

```json
{
  "proposal": {
    "intent": "inspect npm install network behavior",
    "capability": "network.observe",
    "parameters": { "interface": "eth0", "duration": 60 },
    "complete": false
  }
}
```

`complete: true` is terminal and does not execute. An executable proposal without `capability` is rejected.

## Current limitations (read this)

- Gateway sessions are in-memory; there is no durable experiment database.
- Gateway has no auth.
- Built-in reasoner proposals are not auto-executed; the host must re-submit them.
- CrewAI `LLM` and `VercelAIReasoner` do not share provider configuration.
- `scope` enforcement in the contract evaluator is currently `working_directory` vs `scope.paths`. Networks, hosts, and egress still need adapter/policy backing.
- Adapter evidence is recorded as `kind: artifact` from evidence URIs. Map those to `process` / `network` / `log` in the host if you rely on `destroy.require_evidence_sealed`.
- Approval remains a CAR control-plane concern. No LLM can grant it.
- This is an integration prototype, not a production lab platform.

## Tests that lock the boundary

```bash
npm test
```

Covered here: recipe compilation of contract clauses, contract deny codes, policy denial before adapters, missing capability on a proposal, allowlist denial even when an adapter exists, and rejection of proposal fields such as `command`.
