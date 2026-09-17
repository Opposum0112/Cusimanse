import { proxyActivities } from "@temporalio/workflow";
import type { ExecutionResult, RuntimeContext } from "../spi/types.js";
import type { CompiledIR } from "../../ir/types.js";

type RuntimeActivity = { executeRuntime(input: { runId: string; ir: CompiledIR; providerId: string }): Promise<ExecutionResult> };
const activities = proxyActivities<RuntimeActivity>({ startToCloseTimeout: "30 minutes", retry: { maximumAttempts: 3 } });

export interface TemporalResearchRun {
  runId: string;
  ir: CompiledIR;
  providerId: string;
}

export async function executeResearchRun(input: TemporalResearchRun): Promise<ExecutionResult> {
  return activities.executeRuntime(input);
}
