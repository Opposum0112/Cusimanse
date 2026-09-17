import { getComputeProvider } from "../../adapters/compute/factory.js";
import { InMemoryRuntime } from "../local-driver.js";
import type { ExecutionResult } from "../spi/types.js";
import type { CompiledIR } from "../../ir/types.js";
import type { ResearchEvent } from "../../agent/research-state.js";

export interface RuntimeActivityResult {
  execution: ExecutionResult;
  researchEvents: ResearchEvent[];
}

export async function executeRuntime(input: { runId: string; ir: CompiledIR; providerId: string }): Promise<RuntimeActivityResult> {
  const compute = await getComputeProvider(input.providerId);
  const runtime = new InMemoryRuntime();
  const execution = await runtime.execute({ runId: input.runId, ir: input.ir, compute });
  const researchEvents: ResearchEvent[] = [
    { type: "observation.recorded", observation: execution.telemetry },
    ...execution.artifacts.references.map((reference) => ({ type: "evidence.recorded" as const, evidenceId: reference.uri })),
  ];
  return { execution, researchEvents };
}
