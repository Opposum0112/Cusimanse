import { ToolLoopAgent } from "ai";
import type { AgentDependencies, AgentTurn, ResearchObjective, ResearchResult, SecurityResearchAgent } from "./types.js";

export class AutonomousThreatResearchAgent implements SecurityResearchAgent {
  constructor(private readonly deps: AgentDependencies) {}

  async investigate(objective: ResearchObjective): Promise<ResearchResult> {
    const started = Date.now();
    const runId = crypto.randomUUID();
    const traceId = crypto.randomUUID();
    const turns: AgentTurn[] = [];
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

    emit("planning", "research.start", objective);

    const agent = new ToolLoopAgent({
      model: this.deps.model,
      instructions: [
        "You are the Cusimanse autonomous threat-research agent.",
        "Investigate the supplied objective using only declared capabilities and available tools.",
        "Treat tool results as observations, form testable hypotheses, and continue until the objective is sufficiently investigated.",
        "Never bypass policy, sandbox, scope, approval, or evidence requirements.",
        "If a tool requires approval, stop and surface the approval requirement; never attempt a bypass.",
      ].join("\n"),
      tools: this.deps.tools,
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
        emit(success ? "observation" : "failed", "tool.finish", {
          toolName: toolCall.toolName,
          toolCallId: toolCall.toolCallId,
          durationMs,
          success,
        });
      },
      onStepEnd: ({ stepNumber, usage, finishReason, toolCalls, toolResults }) => {
        emit("analysis", "agent.step", {
          stepNumber,
          finishReason,
          usage,
          toolCallCount: toolCalls.length,
          toolResultCount: toolResults.length,
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
        ...(this.deps.maxSteps === undefined ? {} : { stopWhen: ({ steps }) => steps.length >= this.deps.maxSteps }),
        runtimeContext: { runId, traceId, objectiveId: objective.id },
      });

      emit("completed", "research.complete", {
        steps: result.steps.length,
        finishReason: result.finishReason,
        usage: result.totalUsage,
        text: result.text,
      });
      return {
        runId,
        traceId,
        success: true,
        objective,
        findings: [result.text],
        turns,
        durationMs: Date.now() - started,
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
        error: error instanceof Error ? error : new Error(String(error)),
      };
    }
  }
}
