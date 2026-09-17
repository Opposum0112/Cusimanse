import { ToolLoopAgent } from "ai";
import type { AgentDependencies, AgentTurn, ResearchObjective, ResearchResult, SecurityResearchAgent } from "./types.js";
import { applyResearchEvent, createAutonomousResearchState, shouldTerminate, transitionPhase, type ResearchEvent, recordObservation } from "./research-state.js";

const RESEARCH_EVENT_TYPES = new Set(["phase.changed", "observation.recorded", "evidence.recorded", "hypothesis.proposed", "hypothesis.status", "finding.proposed", "finding.verified"]);
function isResearchEvent(value: unknown): value is ResearchEvent { return typeof value === "object" && value !== null && "type" in value && RESEARCH_EVENT_TYPES.has(String((value as { type: unknown }).type)); }
function readToolOutput(value: unknown): unknown { if (typeof value !== "object" || value === null) return undefined; return "output" in value ? (value as { output: unknown }).output : undefined; }

export class AutonomousThreatResearchAgent implements SecurityResearchAgent {
  constructor(private readonly deps: AgentDependencies) {}
  async investigate(objective: ResearchObjective): Promise<ResearchResult> {
    const started = Date.now(); const runId = crypto.randomUUID(); const traceId = crypto.randomUUID(); const turns: AgentTurn[] = [];
    const maxSteps = this.deps.maxSteps ?? 12; let researchState = createAutonomousResearchState(objective.id, maxSteps);
    const emit = (event: AgentTurn["event"], name: string, data?: unknown): void => { const turn: AgentTurn = { runId, traceId, step: turns.length + 1, event, name, ...(data === undefined ? {} : { data }), timestamp: new Date().toISOString() }; turns.push(turn); this.deps.onTurn?.(turn); };
    const changePhase = (phase: typeof researchState.phase): void => { if (researchState.phase === phase) return; try { researchState = transitionPhase(researchState, phase); emit("analysis", "research.phase", { phase }); } catch (error) { emit("failed", "research-phase.rejected", { from: researchState.phase, to: phase, message: error instanceof Error ? error.message : String(error) }); } };
    const applyEvent = (event: ResearchEvent, causationId?: string): void => { try { researchState = applyResearchEvent(researchState, event); emit("analysis", "research.event", { event, causationId }); } catch (error) { emit("failed", "research-event.rejected", { type: event.type, message: error instanceof Error ? error.message : String(error), causationId }); } };

    emit("planning", "research.start", { objective, maxSteps, phase: researchState.phase });
    const agent = new ToolLoopAgent({
      model: this.deps.model,
      instructions: ["You are the Cusimanse autonomous threat-research agent.", "Follow PLAN -> HYPOTHESIZE -> EXECUTE -> OBSERVE -> ANALYZE -> VERIFY -> REPLAN or TERMINATE.", "Use only declared capabilities and available tools.", "Treat tool results as observations and use structured researchEvent outputs for authoritative state transitions.", "Never fabricate evidence or bypass policy, sandbox, scope, approval, or evidence requirements."].join("\n"),
      tools: this.deps.tools,
      stopWhen: ({ steps }) => steps.length >= maxSteps || shouldTerminate(researchState),
      ...(this.deps.approval === undefined ? {} : { toolApproval: ({ toolCall }) => this.deps.approval?.evaluate(toolCall.toolName, toolCall.input) ?? "denied" }),
      telemetry: { isEnabled: true, recordInputs: false, recordOutputs: false, functionId: "cusimanse.threat-research", metadata: { runId, traceId, objectiveId: objective.id } },
      experimental_onStart: ({ model, functionId }) => emit("planning", "model.start", { provider: model.provider, modelId: model.modelId, functionId }),
      experimental_onToolCallStart: ({ toolCall }) => { changePhase("executing"); emit("tool-call", "tool.start", { toolName: toolCall.toolName, toolCallId: toolCall.toolCallId }); },
      experimental_onToolCallFinish: ({ toolCall, durationMs, success }) => { const observation = { toolName: toolCall.toolName, toolCallId: toolCall.toolCallId, durationMs, success }; applyEvent({ type: "observation.recorded", observation }, toolCall.toolCallId); changePhase("observing"); emit(success ? "observation" : "failed", "tool.finish", observation); },
      onStepEnd: ({ stepNumber, usage, finishReason, toolCalls, toolResults }) => {
        for (const toolResult of toolResults) { const candidate = readToolOutput(toolResult); if (isResearchEvent(candidate)) applyEvent(candidate); }
        if (shouldTerminate(researchState)) { if (researchState.phase !== "completed") { if (researchState.phase === "observing") changePhase("analyzing"); if (researchState.phase === "analyzing") changePhase("verifying"); changePhase("completed"); } }
        else { if (researchState.phase === "observing") changePhase("analyzing"); if (researchState.phase === "analyzing" && researchState.findings.some((f) => f.verification === "unverified")) changePhase("verifying"); if (researchState.phase === "analyzing" || researchState.phase === "verifying") changePhase("replanning"); if (researchState.phase === "replanning") changePhase("hypothesizing"); }
        emit("analysis", "agent.step", { stepNumber, finishReason, usage, toolCallCount: toolCalls.length, toolResultCount: toolResults.length, phase: researchState.phase, terminating: shouldTerminate(researchState) });
      },
    });
    try {
      changePhase("hypothesizing");
      const result = await agent.generate({ prompt: [`Research objective ID: ${objective.id}`, `Question: ${objective.question}`, `Scope: ${JSON.stringify(objective.scope ?? {})}`, `Constraints: ${JSON.stringify(objective.constraints ?? {})}`, "Begin the investigation and produce a concise evidence-grounded final result."].join("\n"), runtimeContext: { runId, traceId, objectiveId: objective.id } });
      if (!shouldTerminate(researchState) && researchState.phase !== "completed") { if (researchState.phase === "hypothesizing") changePhase("analyzing"); if (researchState.phase === "analyzing") changePhase("completed"); }
      emit("completed", "research.complete", { steps: result.steps.length, finishReason: result.finishReason, usage: result.totalUsage, text: result.text, researchState });
      return { runId, traceId, success: true, objective, findings: [result.text], turns, durationMs: Date.now() - started, researchState };
    } catch (error) { emit("failed", "research.failed", { message: error instanceof Error ? error.message : String(error), phase: researchState.phase }); return { runId, traceId, success: false, objective, findings: [], turns, durationMs: Date.now() - started, researchState, error: error instanceof Error ? error : new Error(String(error)) }; }
  }
}
