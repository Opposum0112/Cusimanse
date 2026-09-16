import { ToolLoopAgent, type ToolSet } from "ai";
import { WorkflowAgent } from "@ai-sdk/workflow";
import type { LanguageModel } from "ai";

export interface AgentRuntimeContext {
  experimentId: string;
  runId: string;
}

export interface CusimanseAgentOptions {
  model: LanguageModel;
  tools?: ToolSet;
  instructions?: string;
  runtimeContext?: AgentRuntimeContext;
}

const defaultInstructions =
  "You are the proposal-only reasoning layer of Cusimanse. " +
  "You may inspect declared research state and propose capabilities, but you must never bypass contracts, policy, approvals, isolation, or evidence requirements.";

export function createToolLoopAgent(options: CusimanseAgentOptions): ToolLoopAgent {
  return new ToolLoopAgent({
    model: options.model,
    instructions: options.instructions ?? defaultInstructions,
    tools: options.tools,
    runtimeContext: options.runtimeContext,
  });
}

export function createWorkflowAgent(options: CusimanseAgentOptions): WorkflowAgent {
  return new WorkflowAgent({
    model: options.model,
    instructions: options.instructions ?? defaultInstructions,
    tools: options.tools,
    runtimeContext: options.runtimeContext,
  });
}
