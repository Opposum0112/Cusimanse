import { InMemoryRuntime } from "./local-driver.js";
import type { ExperimentRuntime, RuntimeContext, ExecutionResult } from "./spi/types.js";
export class LangGraphRuntime implements ExperimentRuntime { readonly id = "graph" as const; private readonly local = new InMemoryRuntime(); async execute(ctx: RuntimeContext): Promise<ExecutionResult> { return await this.local.execute(ctx); } async abort(runId: string): Promise<void> { await this.local.abort(runId); } }
