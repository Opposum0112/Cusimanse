import { getComputeProvider } from "../../adapters/compute/factory.js";
import { InMemoryRuntime } from "../local-driver.js";
import type { ExecutionResult } from "../spi/types.js";
import type { CompiledIR } from "../../ir/types.js";

export async function executeRuntime(input: { runId: string; ir: CompiledIR; providerId: string }): Promise<ExecutionResult> {
  const compute = await getComputeProvider(input.providerId);
  const runtime = new InMemoryRuntime();
  return runtime.execute({ runId: input.runId, ir: input.ir, compute });
}
