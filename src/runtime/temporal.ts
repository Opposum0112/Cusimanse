import type { CusimanseIR } from "../ir/index.js";
import type { ResearchState } from "../state/index.js";
import type { ExecutionRuntime, RuntimeContext } from "./types.js";

/** SPI seam for Temporal. A Temporal worker owns durable execution; this package owns no Temporal SDK state. */
export interface TemporalWorkflowDriver {
  execute(ir: CusimanseIR, state: ResearchState, context: RuntimeContext): Promise<ResearchState>;
}

export class TemporalExecutionRuntime implements ExecutionRuntime {
  readonly id = "temporal" as const;
  constructor(private readonly driver?: TemporalWorkflowDriver) {}
  async run(ir: CusimanseIR, state: ResearchState, context?: RuntimeContext): Promise<ResearchState> {
    if (!this.driver) throw new Error("Temporal runtime is not configured. Register a TemporalWorkflowDriver.");
    return this.driver.execute(ir, state, context ?? { runId: crypto.randomUUID() });
  }
}
