# LLM and reasoning layer

CAR does not treat the model as an executor. The model may only emit a **typed proposal**. Execution stays in the contract → policy → adapter path.

There are **two supported operator setups**. Pick one per experiment unless you have a clear hand-off.

| Setup | Where the model lives | How it talks to CAR | Use when |
|---|---|---|---|
| **A. Built-in CAR reasoner** | TypeScript `src/llm` inside `RuntimeOrchestrator` | In-process `Reasoner.reason(state)` after a runtime cycle | Single model, no multi-agent crew |
| **B. CrewAI as operator** | External Python CrewAI process | HTTP tools: propose / get state / get evidence | Roles, delegation, multi-agent review |

Do **not** give either setup a shell tool, Lima API, or policy-edit API.

## Shared proposal schema

Both setups must produce the same shape (`reasoningProposalSchema` in `src/llm/index.ts`):

```ts
{
  intent: string;       // research English, not a command
  capability?: string;  // required to execute
  parameters?: object;  // capability fields only
  complete: boolean;    // true = stop, no execution
}
```

The schema is strict. Extra keys such as `command` or `shell` fail validation.

System rule for any model you attach:

> Propose declarative research intent only. Never assume authorization, credentials, host access, policy changes, or approval. Never emit shell commands or direct execution instructions.

## Setup A — configure the built-in reasoner

`VercelAIReasoner` uses Vercel AI SDK 7 `generateText` + `Output.object`. No AI-SDK tools are registered. The model sees `ResearchState` JSON and must return one proposal.

```ts
import { openai } from "@ai-sdk/openai"; // or any AI SDK 7 provider
import { VercelAIReasoner } from "./src/llm/index.js";
import { RuntimeOrchestrator } from "./src/runtime/index.js";

const reasoner = new VercelAIReasoner({
  model: openai("gpt-4.1"),
  // optional; default text already forbids execution claims
  system:
    "You are the proposal-only reasoning layer of CAR. " +
    "Read experiment state and propose the next {intent, capability, parameters, complete}. " +
    "Stay inside the frozen contract allowlist. Never invent shell or approval.",
});

const runtime = new RuntimeOrchestrator({
  capabilities,
  policy,
  approvals,
  operations,
  adapters,
  reasoner, // omit this field for a fully human-driven loop
});

const result = await runtime.run(compiledIr, state);
// result.proposals[0] is untrusted data. Feed it back through
// gateway.submitProposal or a second runtime.run of that intent.
```

What the built-in reasoner **does**

- runs *after* the planned intents in that `runtime.run` cycle
- returns `result.proposals`
- does not call adapters itself

What it **does not do**

- does not skip contract or policy checks
- does not approve `approval-required` operations
- does not destroy VMs
- is not CrewAI

To use the proposal, the host must submit it again as a new intent (gateway or `runtime.run` with that single intent). Treat it like any other untrusted input.

Provider configuration is the host's job (API keys, model id). CAR only requires a Vercel AI SDK `LanguageModel`.

## Setup B — CrewAI as operator

CrewAI is an **external operator**, not a CAR subsystem. The crew reasons and delegates; it may only use `CAR_TOOLS`.

```python
import os
from crewai import Agent, Task, Crew, LLM
from integrations.crewai.cusimanse_tools import CAR_TOOLS

os.environ["CUSIMANSE_CAR_URL"] = "http://127.0.0.1:8787"

# CrewAI's own LLM — this is not VercelAIReasoner
llm = LLM(model=os.environ.get("CREWAI_MODEL", "gpt-4.1"))

researcher = Agent(
    role="Threat Researcher",
    goal="Investigate the frozen research question using only CAR skills",
    backstory=(
        "You operate a security lab through CAR. You never run shell. "
        "You submit typed proposals with an explicit capability from the "
        "contract allowlist, then read state and evidence."
    ),
    llm=llm,
    tools=CAR_TOOLS,
    allow_delegation=False,
    verbose=True,
)

reviewer = Agent(
    role="Research Reviewer",
    goal="Check whether required evidence exists and whether the run should complete",
    llm=llm,
    tools=CAR_TOOLS,  # read-only use: state + evidence; complete=true to stop
    allow_delegation=False,
)

investigate = Task(
    description=(
        "Experiment id: npm-install-example. "
        "Use car_get_research_state, then propose only allowlisted capabilities. "
        "Do not request host.shell or policy changes."
    ),
    expected_output="A sequence of CAR proposals and a short analysis of evidence",
    agent=researcher,
)

crew = Crew(agents=[researcher, reviewer], tasks=[investigate])
crew.kickoff()
```

Rules for this operator:

- Give agents **only** `CAR_TOOLS` (`car_submit_research_proposal`, `car_get_research_state`, `car_get_evidence`).
- Point `CUSIMANSE_CAR_URL` at loopback.
- Map roles to skills in `skills/registry.yaml`; do not invent capabilities.
- The CrewAI `LLM(...)` object is independent of `VercelAIReasoner`. Do not assume they share providers or prompts.
- Do not also inject `VercelAIReasoner` on the same cycle unless the host discards one of the two proposal streams. Two operators proposing in parallel will fight the contract budget (`max_proposals`).

## Which setup should I use?

- Need one model to suggest the next step after a planned recipe run → **Setup A**.
- Need named lab roles (researcher, detection engineer, reviewer) → **Setup B**.
- Human only clicks through intents → omit `reasoner` and do not start CrewAI.

Both setups are optional. CAR runs contracts with zero LLM.

## What neither setup may configure

- AI SDK / CrewAI tools that exec, SSH, or call Lima
- Prompts that claim the model has already been approved
- Skill YAML that embeds commands or credentials
- A second gateway that bypasses `evaluateContractIntent`
