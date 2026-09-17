import { proxyActivities } from "@temporalio/workflow";
import { applyResearchEvent, createAutonomousResearchState, type AutonomousResearchState, type ResearchEvent } from "../../agent/research-state.js";
import type { ExecutionResult } from "../spi/types.js";
import type { CompiledIR } from "../../ir/types.js";
import type { RuntimeActivityResult } from "./activities.js";

/**
 * Temporal workflow owns the durable orchestration boundary. All runtime work
 * remains in Activities so the workflow stays deterministic and replay-safe.
 */
type RuntimeActivity = {
  executeRuntime(input: { runId: string; ir: CompiledIR; providerId: string }): Promise<RuntimeActivityResult>;
};

const activities = proxyActivities<RuntimeActivity>({
  startToCloseTimeout: "30 minutes",
  retry: { maximumAttempts: 3 },
});

export interface TemporalResearchRun {
  runId: string;
  ir: CompiledIR;
  providerId: string;
  objectiveId?: string;
  maxIterations?: number;
}

export interface TemporalResearchState {
  runId: string;
  phase: "created" | "executing" | "completed" | "failed";
  research: AutonomousResearchState;
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
    research: createAutonomousResearchState(input.objectiveId ?? input.runId, input.maxIterations ?? 12),
  };

  try {
    state = { ...state, phase: "executing" };
    const activity = await activities.executeRuntime(input);
    for (const event of activity.researchEvents as ResearchEvent[]) {
      state = { ...state, research: applyResearchEvent(state.research, event) };
    }
    state = {
      ...state,
      phase: activity.execution.success ? "completed" : "failed",
    };
    return { execution: activity.execution, state };
  } catch (error) {
    state = {
      ...state,
      phase: "failed",
      lastError: error instanceof Error ? error.message : String(error),
    };
    throw error;
  }
}
