import { ToolLoopAgent, type ToolSet, type LanguageModel } from "ai";

export interface AgentRuntimeContext extends Record<string, unknown> {
  experimentId: string;
  runId: string;
}
export interface CusimanseAgentOptions {
  model: LanguageModel;
  tools?: ToolSet;
  instructions?: string;
  runtimeContext?: AgentRuntimeContext;
}
const defaultInstructions = "You are the proposal-only reasoning layer of Cusimanse. You may inspect declared research state and propose capabilities, but you must never bypass contracts, policy, approvals, isolation, or evidence requirements.";

export function createToolLoopAgent(options: CusimanseAgentOptions): ToolLoopAgent {
  return new ToolLoopAgent({
    model: options.model,
    instructions: options.instructions ?? defaultInstructions,
    ...(options.tools ? { tools: options.tools } : {}),
    ...(options.runtimeContext ? { runtimeContext: options.runtimeContext } : {}),
  });
}

export function createWorkflowAgent(options: CusimanseAgentOptions): ToolLoopAgent {
  // AI SDK 7's ToolLoopAgent provides the runtime-neutral agent primitive.
  // Workflow orchestration remains a runtime concern, so no separate
  // @ai-sdk/workflow package is required.
  return createToolLoopAgent(options);
}
