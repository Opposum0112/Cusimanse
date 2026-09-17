import type { LanguageModel, ToolSet } from "ai";
import type { ComputeProvider } from "../adapters/compute/types.js";
import type { ExperimentRuntime } from "../runtime/spi/types.js";
import type { FailClosedToolApproval } from "../policy/approval.js";
import type { ResearchObjective, SecurityResearchAgent } from "./types.js";

/**
 * Vercel-native execution contract.
 *
 * This boundary deliberately keeps Cusimanse policy, compute, and research
 * state outside the model substrate. The concrete WorkflowAgent integration
 * can evolve independently from the security-research domain model.
 */
export interface VercelAgentRuntimeConfig {
  model: LanguageModel;
  tools: ToolSet;
  compute: ComputeProvider;
  runtime: ExperimentRuntime;
  approval?: FailClosedToolApproval;
  maxSteps?: number;
}

export interface VercelAgentRuntime extends SecurityResearchAgent {
  readonly kind: "vercel-ai-sdk-7";
  readonly config: Readonly<VercelAgentRuntimeConfig>;
}

export function createVercelAgentRuntime(config: VercelAgentRuntimeConfig): VercelAgentRuntime {
  if (!config.model) throw new Error("Vercel AI runtime requires a model.");
  if (!config.tools) throw new Error("Vercel AI runtime requires a tool set.");
  if (!config.compute) throw new Error("Vercel AI runtime requires a compute provider.");
  if (!config.runtime) throw new Error("Vercel AI runtime requires an execution runtime.");

  return {
    kind: "vercel-ai-sdk-7",
    config: Object.freeze({ ...config }),
    async investigate(objective: ResearchObjective) {
      const { createResearchAgent } = await import("./workflow-agent.js");
      return createResearchAgent(config).investigate(objective);
    },
  };
}
