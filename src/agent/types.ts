import type { LanguageModel } from "ai";
import type { ComputeProvider } from "../adapters/compute/types.js";
import type { ExperimentRuntime } from "../runtime/spi/types.js";

export interface ResearchObjective {
  id: string;
  question: string;
  scope?: Record<string, unknown>;
  constraints?: Record<string, unknown>;
}

export interface ResearchToolContext {
  runId: string;
  traceId: string;
  objective: ResearchObjective;
  compute: ComputeProvider;
  runtime: ExperimentRuntime;
}

export interface AgentTurn {
  runId: string;
  traceId: string;
  step: number;
  event: "planning" | "tool-call" | "observation" | "analysis" | "completed" | "failed";
  name: string;
  data?: unknown;
  timestamp: string;
}

export interface ResearchResult {
  runId: string;
  traceId: string;
  success: boolean;
  objective: ResearchObjective;
  findings: unknown[];
  turns: AgentTurn[];
  durationMs: number;
  error?: Error;
}

export interface SecurityResearchAgent {
  investigate(objective: ResearchObjective): Promise<ResearchResult>;
}

export interface AgentDependencies {
  model: LanguageModel;
  tools: Record<string, unknown>;
  compute: ComputeProvider;
  runtime: ExperimentRuntime;
  maxSteps?: number;
  onTurn?: (turn: AgentTurn) => void;
}
