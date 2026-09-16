import type { CusimanseIR } from "../ir/index.js";
import type { ResearchState } from "../state/index.js";

export interface RuntimeContext {
  readonly runId: string;
  readonly signal?: AbortSignal;
}

export interface ExecutionRuntime {
  readonly id: "local" | "temporal" | "graph" | (string & {});
  run(ir: CusimanseIR, state: ResearchState, context?: RuntimeContext): Promise<ResearchState>;
}

export class ExecutionRuntimeRegistry {
  private readonly runtimes = new Map<string, ExecutionRuntime>();
  register(runtime: ExecutionRuntime): void {
    if (this.runtimes.has(runtime.id)) throw new Error(`Execution runtime already registered: ${runtime.id}`);
    this.runtimes.set(runtime.id, runtime);
  }
  get(id: string): ExecutionRuntime {
    const runtime = this.runtimes.get(id);
    if (!runtime) throw new Error(`Execution runtime not registered: ${id}`);
    return runtime;
  }
  list(): ExecutionRuntime[] { return [...this.runtimes.values()].sort((a, b) => a.id.localeCompare(b.id)); }
}
