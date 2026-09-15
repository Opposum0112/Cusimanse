import type { Operation, OperationResult } from "../operations/index.js";

export interface RuntimeState {
  experimentId: string;
  phase: string;
  observations: unknown[];
  evidenceRefs: string[];
  operationResults: OperationResult[];
}

export interface CapabilityResolver {
  resolve(capability: string, parameters?: unknown): Promise<Operation>;
}

export interface PolicyEngine {
  authorize(operation: Operation): Promise<"allow" | "deny" | "approval-required">;
}

export interface OperationExecutor {
  execute(operation: Operation, state: RuntimeState): Promise<OperationResult>;
}

export interface ReasoningResult {
  intent: string;
  capability?: string;
  parameters?: Record<string, unknown>;
  complete: boolean;
}

export interface Reasoner {
  reason(state: RuntimeState): Promise<ReasoningResult>;
}

export class CusimanseAgentRuntime {
  constructor(
    private readonly resolver: CapabilityResolver,
    private readonly policy: PolicyEngine,
    private readonly executor: OperationExecutor,
    private readonly reasoner?: Reasoner,
  ) {}

  async step(state: RuntimeState): Promise<RuntimeState> {
    const proposal = this.reasoner
      ? await this.reasoner.reason(state)
      : { intent: "recipe-complete", complete: true };

    if (proposal.complete || !proposal.capability) return state;

    const operation = await this.resolver.resolve(proposal.capability, proposal.parameters);
    const decision = await this.policy.authorize(operation);

    if (decision !== "allow") {
      return {
        ...state,
        operationResults: [...state.operationResults, {
          operationId: operation.id,
          status: "denied",
          error: decision,
          evidenceRefs: [],
        }],
      };
    }

    const result = await this.executor.execute(operation, state);
    return { ...state, operationResults: [...state.operationResults, result] };
  }
}
