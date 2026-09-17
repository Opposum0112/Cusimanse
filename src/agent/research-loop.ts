import { ToolLoopAgent } from "ai";
import type { AgentDependencies, AgentTurn, ResearchObjective, ResearchResult, SecurityResearchAgent } from "./types.js";
import { applyResearchEvent, createAutonomousResearchState, type ResearchEvent, recordObservation } from "./research-state.js";

const RESEARCH_EVENT_TYPES = new Set([
  "observation.recorded",
  "evidence.recorded",
  "hypothesis.proposed",
  "hypothesis.status",
  "finding.proposed",
  "finding.verified",
]);

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
      const turn: AgentTurn = {
        runId,
        traceId,
        step: turns.length + 1,
        event,
        name,
        ...(data === undefined ? {} : { data }),
        timestamp: new Date().toISOString(),
      };
      turns.push(turn);
      this.deps.onTurn?.(turn);
    };

    emit("planning", "research.start", { objective, maxSteps });

    const agent = new ToolLoopAgent({
      model: this.deps.model,
      instructions: [
        "You are the Cusimanse autonomous threat-research agent.",
        "Investigate the supplied objective using only declared capabilities and available tools.",
        "Treat tool results as observations, form testable hypotheses, and continue until the objective is sufficiently investigated.",
        "When a trusted research tool returns a structured researchEvent, the runtime will validate and apply it to research state.",
        "Research events may propose hypotheses or findings, attach evidence, change hypothesis status, or verify findings; never fabricate evidence references.",
        "Never bypass policy, sandbox, scope, approval, or evidence requirements.",
        "If a tool requires approval, stop and surface the approval requirement; never attempt a bypass.",
      ].join("\n"),
      tools: this.deps.tools,
      stopWhen: ({ steps }) => steps.length >= maxSteps,
      ...(this.deps.approval === undefined ? {} : {
        toolApproval: ({ toolCall }) => this.deps.approval?.evaluate(toolCall.toolName, toolCall.input) ?? "denied",
      }),
      telemetry: {
        isEnabled: true,
        recordInputs: false,
        recordOutputs: false,
        functionId: "cusimanse.threat-research",
        metadata: { runId, traceId, objectiveId: objective.id },
      },
      experimental_onStart: ({ model, functionId }) => {
        emit("planning", "model.start", { provider: model.provider, modelId: model.modelId, functionId });
      },
      experimental_onToolCallStart: ({ toolCall }) => {
        emit("tool-call", "tool.start", { toolName: toolCall.toolName, toolCallId: toolCall.toolCallId });
      },
      experimental_onToolCallFinish: ({ toolCall, durationMs, success }) => {
        const observation = { toolName: toolCall.toolName, toolCallId: toolCall.toolCallId, durationMs, success };
        researchState = recordObservation(researchState, observation);
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
            emit("failed", "research-event.rejected", {
              type: candidate.type,
              message: error instanceof Error ? error.message : String(error),
            });
          }
        }
        emit("analysis", "agent.step", {
          stepNumber,
          finishReason,
          usage,
          toolCallCount: toolCalls.length,
          toolResultCount: toolResults.length,
          appliedResearchEvents: appliedEvents,
        });
      },
    });

    try {
      const result = await agent.generate({
        prompt: [
          `Research objective ID: ${objective.id}`,
          `Question: ${objective.question}`,
          `Scope: ${JSON.stringify(objective.scope ?? {})}`,
          `Constraints: ${JSON.stringify(objective.constraints ?? {})}`,
          "Begin the investigation and produce a concise evidence-grounded final result.",
        ].join("\n"),
        runtimeContext: { runId, traceId, objectiveId: objective.id },
      });

      emit("completed", "research.complete", {
        steps: result.steps.length,
        finishReason: result.finishReason,
        usage: result.totalUsage,
        text: result.text,
        researchState,
      });
      return {
        runId,
        traceId,
        success: true,
        objective,
        findings: [result.text],
        turns,
        durationMs: Date.now() - started,
        researchState,
      };
    } catch (error) {
      emit("failed", "research.failed", { message: error instanceof Error ? error.message : String(error) });
      return {
        runId,
        traceId,
        success: false,
        objective,
        findings: [],
        turns,
        durationMs: Date.now() - started,
        researchState,
        error: error instanceof Error ? error : new Error(String(error)),
      };
    }
  }
}
