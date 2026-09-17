import type { LanguageModel, ToolSet } from "ai";
import type { ComputeProvider } from "../adapters/compute/types.js";
import type { ExperimentRuntime } from "../runtime/spi/types.js";
import type { FailClosedToolApproval } from "../policy/approval.js";

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
  tools: ToolSet;
  compute: ComputeProvider;
  runtime: ExperimentRuntime;
  approval?: FailClosedToolApproval;
  maxSteps?: number;
  onTurn?: (turn: AgentTurn) => void;
}
