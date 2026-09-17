import { WorkflowAgent, type LanguageModel, type ToolSet } from "@ai-sdk/workflow";
import type { ComputeProvider } from "../adapters/compute/types.js";
import type { ExperimentRuntime } from "../runtime/spi/types.js";
import type { FailClosedToolApproval } from "../policy/approval.js";
import { createAutonomousResearchState } from "../state/research.js";
import type { ResearchObjective, ResearchResult, SecurityResearchAgent } from "./types.js";

export interface WorkflowAgentConfig {
  model: LanguageModel;
  tools: ToolSet;
  compute: ComputeProvider;
  runtime: ExperimentRuntime;
  approval?: FailClosedToolApproval;
  maxSteps?: number;
}

/**
 * Vercel AI SDK 7 durable agent boundary.
 *
 * WorkflowAgent owns resumability/durable execution. Cusimanse still owns
 * authorization, research state, evidence provenance, and compute isolation.
 */
export function createResearchAgent(config: WorkflowAgentConfig): SecurityResearchAgent {
  return {
    async investigate(objective: ResearchObjective): Promise<ResearchResult> {
      const started = Date.now();
      const runId = `run-${Math.random().toString(36).slice(2, 10)}`;
      const traceId = `trace-${Math.random().toString(36).slice(2, 10)}`;
      const turns: ResearchResult["turns"] = [];
      const researchState = createAutonomousResearchState(objective.id, config.maxSteps ?? 12);

      const agent = new WorkflowAgent({
        model: config.model,
        tools: config.tools,
        instructions: [
          "You are the Cusimanse autonomous security research agent.",
          "Plan investigations and use only governed research tools.",
          "Cusimanse policy and approval are authoritative; never bypass them.",
          "Do not fabricate observations, evidence, findings, or tool results.",
          "Treat tool outputs as research observations and preserve evidence provenance.",
        ].join(" "),
        stopWhen: ({ steps }) => steps.length >= (config.maxSteps ?? 12),
        experimental_telemetry: { isEnabled: true, recordInputs: false, recordOutputs: false },
      });

      turns.push({ runId, traceId, step: 0, event: "planning", name: "research.start", data: { objectiveId: objective.id }, timestamp: new Date().toISOString() });
      try {
        await agent.generate({ prompt: objective.question });
        turns.push({ runId, traceId, step: 1, event: "completed", name: "research.complete", timestamp: new Date().toISOString() });
        return { runId, traceId, success: true, objective, findings: [], turns, durationMs: Date.now() - started, researchState };
      } catch (error) {
        turns.push({ runId, traceId, step: 1, event: "failed", name: "research.failed", data: error instanceof Error ? error.message : String(error), timestamp: new Date().toISOString() });
        return { runId, traceId, success: false, objective, findings: [], turns, durationMs: Date.now() - started, researchState, error: error instanceof Error ? error : new Error(String(error)) };
      }
    },
  };
}
