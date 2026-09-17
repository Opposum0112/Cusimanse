import { proxyActivities } from "@temporalio/workflow";
import { applyResearchEvent, createAutonomousResearchState, shouldTerminate, type AutonomousResearchState, type ResearchEvent } from "../../state/research.js";
import type { CusimanseEvent, ResearchEventEnvelope } from "../../state/index.js";
import type { ExecutionResult } from "../spi/types.js";
import type { CompiledIR } from "../../ir/types.js";
import type { RuntimeActivityResult } from "./activities.js";

/**
 * Temporal owns durable orchestration. Model/tool execution remains outside the
 * workflow in Activities so replay remains deterministic.
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
  events: CusimanseEvent[];
  revision: number;
  lastError?: string;
}

export interface TemporalResearchRunResult {
  execution: ExecutionResult;
  state: TemporalResearchState;
}

function appendResearchEvent(state: TemporalResearchState, event: ResearchEvent): TemporalResearchState {
  const research = applyResearchEvent(state.research, event);
  const sequence = state.revision + 1;
  const envelope: ResearchEventEnvelope = {
    id: `${state.runId}:research:${sequence}`,
    type: "research",
    experimentId: state.runId,
    timestamp: new Date().toISOString(),
    payload: event,
    sequence,
  };
  return { ...state, research, events: [...state.events, envelope], revision: sequence };
}

function changePhase(state: TemporalResearchState, phase: AutonomousResearchState["phase"]): TemporalResearchState {
  if (state.research.phase === phase) return state;
  return appendResearchEvent(state, { type: "phase.changed", phase });
}

export async function executeResearchRun(input: TemporalResearchRun): Promise<TemporalResearchRunResult> {
  const maxIterations = input.maxIterations ?? 12;
  let state: TemporalResearchState = {
    runId: input.runId,
    phase: "created",
    research: createAutonomousResearchState(input.objectiveId ?? input.runId, maxIterations),
    events: [],
    revision: 0,
  };
  let lastExecution: ExecutionResult | undefined;

  try {
    state = { ...state, phase: "executing" };

    while (!shouldTerminate(state.research)) {
      state = changePhase(state, "hypothesizing");
      state = changePhase(state, "executing");

      const activity = await activities.executeRuntime(input);
      lastExecution = activity.execution;

      for (const event of activity.researchEvents) {
        state = appendResearchEvent(state, event);
      }

      state = changePhase(state, "observing");
      state = changePhase(state, "analyzing");

      if (shouldTerminate(state.research)) {
        state = changePhase(state, "completed");
        break;
      }

      state = changePhase(state, "replanning");
      state = changePhase(state, "planning");
    }

    if (state.research.phase !== "completed") {
      state = changePhase(state, "completed");
    }

    if (!lastExecution) {
      throw new Error("Research run terminated without executing an iteration.");
    }

    return { execution: lastExecution, state };
  } catch (error) {
    state = {
      ...state,
      phase: "failed",
      lastError: error instanceof Error ? error.message : String(error),
    };
    throw error;
  }
}
