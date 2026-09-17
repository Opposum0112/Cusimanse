import { ToolLoopAgent } from "ai";
import type { AgentDependencies, AgentTurn, ResearchObjective, ResearchResult, SecurityResearchAgent } from "./types.js";
import { applyResearchEvent, createAutonomousResearchState, shouldTerminate, transitionPhase, type ResearchEvent, recordObservation } from "./research-state.js";

const RESEARCH_EVENT_TYPES = new Set(["phase.changed", "observation.recorded", "evidence.recorded", "hypothesis.proposed", "hypothesis.status", "finding.proposed", "finding.verified"]);

function isResearchEvent(value: unknown): value is ResearchEvent {
  return typeof value === "object" && value !== null && "type" in value && RESEARCH_EVENT_TYPES.has(String((value as { type: unknown }).type));
}

function readToolOutput(value: unknown): unknown {
  if (typeof value !== "object" || value === null) return undefined;
  if ("output" in value) return (value as { output: unknown }).output;
  return undefined;
}

export class AutonomousThreatResearchAgent implements SecurityResearchAgent {
  constructor(private readonly deps: AgentDependencies) {}

  async investigate(objective: ResearchObjective): Promise<ResearchResult> {
    const started = Date.now();
    const runId = crypto.randomUUID();
    const traceId = crypto.randomUUID();
    const turns: AgentTurn[] = [];
    const maxSteps = this.deps.maxSteps ?? 12;
    let researchState = createAutonomousResearchState(objective.id, maxSteps);

    const emit = (event: AgentTurn["event"], name: string, data?: unknown): void => {
      const turn: AgentTurn = { runId, traceId, step: turns.length + 1, event, name, ...(data === undefined ? {} : { data }), timestamp: new Date().toISOString() };
      turns.push(turn);
      this.deps.onTurn?.(turn);
    };

    const changePhase = (phase: typeof researchState.phase): void => {
      if (researchState.phase === phase) return;
      try {
        researchState = transitionPhase(researchState, phase);
        emit("analysis", "research.phase", { phase });
      } catch (error) {
        emit("failed", "research-phase.rejected", { from: researchState.phase, to: phase, message: error instanceof Error ? error.message : String(error) });
      }
    };

    emit("planning", "research.start", { objective, maxSteps, phase: researchState.phase });

    const agent = new ToolLoopAgent({
      model: this.deps.model,
      instructions: [
        "You are the Cusimanse autonomous threat-research agent.",
        "Follow this research lifecycle: PLAN -> HYPOTHESIZE -> EXECUTE -> OBSERVE -> ANALYZE -> VERIFY -> REPLAN or TERMINATE.",
        "Investigate the supplied objective using only declared capabilities and available tools.",
        "Treat tool results as observations and use structured researchEvent outputs for authoritative state transitions.",
        "Research events may propose hypotheses or findings, attach evidence, change hypothesis status, or verify findings; never fabricate evidence references.",
        "Never bypass policy, sandbox, scope, approval, or evidence requirements.",
        "If a tool requires approval, stop and surface the approval requirement; never attempt a bypass.",
      ].join("\n"),
      tools: this.deps.tools,
      stopWhen: ({ steps }) => steps.length >= maxSteps || shouldTerminate(researchState),
      ...(this.deps.approval === undefined ? {} : {
        toolApproval: ({ toolCall }) => this.deps.approval?.evaluate(toolCall.toolName, toolCall.input) ?? "denied",
      }),
      telemetry: { isEnabled: true, recordInputs: false, recordOutputs: false, functionId: "cusimanse.threat-research", metadata: { runId, traceId, objectiveId: objective.id } },
      experimental_onStart: ({ model, functionId }) => emit("planning", "model.start", { provider: model.provider, modelId: model.modelId, functionId }),
      experimental_onToolCallStart: ({ toolCall }) => {
        changePhase("executing");
        emit("tool-call", "tool.start", { toolName: toolCall.toolName, toolCallId: toolCall.toolCallId });
      },
      experimental_onToolCallFinish: ({ toolCall, durationMs, success }) => {
        const observation = { toolName: toolCall.toolName, toolCallId: toolCall.toolCallId, durationMs, success };
        researchState = recordObservation(researchState, observation);
        changePhase("observing");
        emit(success ? "observation" : "failed", "tool.finish", observation);
      },
      onStepEnd: ({ stepNumber, usage, finishReason, toolCalls, toolResults }) => {
        let appliedEvents = 0;
        for (const toolResult of toolResults) {
          const candidate = readToolOutput(toolResult);
          if (!isResearchEvent(candidate)) continue;
          try {
            researchState = applyResearchEvent(researchState, candidate);
            appliedEvents += 1;
          } catch (error) {
            emit("failed", "research-event.rejected", { type: candidate.type, message: error instanceof Error ? error.message : String(error) });
          }
        }
        if (!shouldTerminate(researchState)) {
          if (researchState.findings.some((finding) => finding.verification === "unverified")) changePhase("verifying");
          else changePhase("analyzing");
          if (!shouldTerminate(researchState)) {
            changePhase("replanning");
            changePhase("hypothesizing");
          }
        } else {
          changePhase("completed");
        }
        emit("analysis", "agent.step", { stepNumber, finishReason, usage, toolCallCount: toolCalls.length, toolResultCount: toolResults.length, appliedResearchEvents: appliedEvents, phase: researchState.phase, terminating: shouldTerminate(researchState) });
      },
    });

    try {
      changePhase("hypothesizing");
      const result = await agent.generate({
        prompt: [`Research objective ID: ${objective.id}`, `Question: ${objective.question}`, `Scope: ${JSON.stringify(objective.scope ?? {})}`, `Constraints: ${JSON.stringify(objective.constraints ?? {})}`, "Begin the investigation and produce a concise evidence-grounded final result."].join("\n"),
        runtimeContext: { runId, traceId, objectiveId: objective.id },
      });

      if (!shouldTerminate(researchState) && researchState.phase !== "completed") {
        changePhase("analyzing");
        changePhase("completed");
      }
      emit("completed", "research.complete", { steps: result.steps.length, finishReason: result.finishReason, usage: result.totalUsage, text: result.text, researchState });
      return { runId, traceId, success: true, objective, findings: [result.text], turns, durationMs: Date.now() - started, researchState };
    } catch (error) {
      emit("failed", "research.failed", { message: error instanceof Error ? error.message : String(error), phase: researchState.phase });
      return { runId, traceId, success: false, objective, findings: [], turns, durationMs: Date.now() - started, researchState, error: error instanceof Error ? error : new Error(String(error)) };
    }
  }
}
