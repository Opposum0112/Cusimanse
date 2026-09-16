import type { CusimanseIR } from "../ir/index.js";
import type { ResearchState } from "../state/index.js";
import type { ExecutionRuntime, RuntimeContext } from "./types.js";

/** Adapter seam for cyclic graph engines such as LangGraph. */
export interface GraphWorkflowDriver {
  execute(ir: CusimanseIR, state: ResearchState, context: RuntimeContext): Promise<ResearchState>;
}

export class GraphExecutionRuntime implements ExecutionRuntime {
  readonly id = "graph" as const;
  constructor(private readonly driver?: GraphWorkflowDriver) {}
  async run(ir: CusimanseIR, state: ResearchState, context?: RuntimeContext): Promise<ResearchState> {
    if (!this.driver) throw new Error("Graph runtime is not configured. Register a GraphWorkflowDriver.");
    return this.driver.execute(ir, state, context ?? { runId: crypto.randomUUID() });
  }
}
