import { generateText, type LanguageModel, type ToolSet } from "ai";
import type { ComputeProvider } from "../adapters/compute/types.js";
import type { ExperimentRuntime } from "../runtime/spi/types.js";
import type { AgentDependencies, AgentTurn, ResearchObjective, ResearchResult, SecurityResearchAgent } from "./types.js";

export class AutonomousThreatResearchAgent implements SecurityResearchAgent {
  constructor(private readonly deps: AgentDependencies) {}

  async investigate(objective: ResearchObjective): Promise<ResearchResult> {
    const started = Date.now();
    const runId = crypto.randomUUID();
    const traceId = crypto.randomUUID();
    const turns: AgentTurn[] = [];
    const emit = (event: AgentTurn["event"], name: string, data?: unknown): void => {
      const turn: AgentTurn = { runId, traceId, step: turns.length + 1, event, name, ...(data === undefined ? {} : { data }), timestamp: new Date().toISOString() };
      turns.push(turn);
      this.deps.onTurn?.(turn);
    };
    emit("planning", "research.start", objective);
    try {
      const result = await generateText({
        model: this.deps.model,
        system: [
          "You are the Cusimanse autonomous threat-research agent.",
          "Investigate the supplied objective using only declared capabilities and available tools.",
          "Treat tool results as observations, form testable hypotheses, and continue until the objective is sufficiently investigated.",
          "Never bypass policy, sandbox, scope, approval, or evidence requirements.",
          `Research objective: ${JSON.stringify(objective)}`
        ].join("\n"),
        prompt: "Begin the investigation. Use tools when evidence is needed and produce a concise final research result.",
        tools: this.deps.tools as ToolSet,
        stopWhen: ({ steps }) => steps.length >= (this.deps.maxSteps ?? 12),
        onStepFinish: ({ toolCalls, toolResults, text }) => {
          if (toolCalls.length > 0) emit("tool-call", "agent.tool-calls", toolCalls);
          if (toolResults.length > 0) emit("observation", "agent.tool-results", toolResults);
          if (text.length > 0) emit("analysis", "agent.text", text);
        }
      });
      emit("completed", "research.complete", { text: result.text, steps: result.steps.length });
      return { runId, traceId, success: true, objective, findings: [result.text], turns, durationMs: Date.now() - started };
    } catch (error) {
      emit("failed", "research.failed", { message: error instanceof Error ? error.message : String(error) });
      return { runId, traceId, success: false, objective, findings: [], turns, durationMs: Date.now() - started, error: error instanceof Error ? error : new Error(String(error)) };
    }
  }
}
