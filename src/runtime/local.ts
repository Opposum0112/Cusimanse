import type { CusimanseIR } from "../ir/index.js";
import type { ResearchState } from "../state/index.js";
import { RuntimeOrchestrator, type RuntimeDependencies } from "./index.js";
import type { ExecutionRuntime, RuntimeContext } from "./types.js";

export class LocalExecutionRuntime implements ExecutionRuntime {
  readonly id = "local" as const;
  constructor(private readonly dependencies: RuntimeDependencies) {}
  async run(ir: CusimanseIR, state: ResearchState, _context?: RuntimeContext): Promise<ResearchState> {
    const result = await new RuntimeOrchestrator(this.dependencies).run(ir, state);
    return result.state;
  }
}
