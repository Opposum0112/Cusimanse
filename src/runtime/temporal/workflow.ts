import { proxyActivities } from "@temporalio/workflow";
import type { ExecutionResult } from "../spi/types.js";
import type { CompiledIR } from "../../ir/types.js";

/**
 * Temporal workflow owns the durable orchestration boundary. All runtime work
 * remains in Activities so the workflow stays deterministic and replay-safe.
 */
type RuntimeActivity = {
  executeRuntime(input: { runId: string; ir: CompiledIR; providerId: string }): Promise<ExecutionResult>;
};

const activities = proxyActivities<RuntimeActivity>({
  startToCloseTimeout: "30 minutes",
  retry: { maximumAttempts: 3 },
});

export interface TemporalResearchRun {
  runId: string;
  ir: CompiledIR;
  providerId: string;
}

export interface TemporalResearchState {
  runId: string;
  phase: "created" | "executing" | "completed" | "failed";
  iteration: number;
  observations: unknown[];
  evidenceIds: string[];
  lastError?: string;
}

export interface TemporalResearchRunResult {
  execution: ExecutionResult;
  state: TemporalResearchState;
}

export async function executeResearchRun(input: TemporalResearchRun): Promise<TemporalResearchRunResult> {
  let state: TemporalResearchState = {
    runId: input.runId,
    phase: "created",
    iteration: 0,
    observations: [],
    evidenceIds: [],
  };

  try {
    state = { ...state, phase: "executing", iteration: state.iteration + 1 };
    const execution = await activities.executeRuntime(input);
    state = {
      ...state,
      phase: execution.success ? "completed" : "failed",
      observations: [execution.telemetry],
      evidenceIds: execution.artifacts.references.map((reference) => reference.uri),
    };
    return { execution, state };
  } catch (error) {
    state = {
      ...state,
      phase: "failed",
      lastError: error instanceof Error ? error.message : String(error),
    };
    throw error;
  }
}
