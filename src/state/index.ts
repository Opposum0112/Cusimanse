export type RuntimePhase =
  | "created"
  | "planning"
  | "awaiting-approval"
  | "executing"
  | "observing"
  | "completed"
  | "failed"
  | "destroying";

export type RuntimeEventType =
  | "experiment.created"
  | "intent.planned"
  | "operation.proposed"
  | "approval.requested"
  | "approval.granted"
  | "approval.denied"
  | "operation.started"
  | "operation.succeeded"
  | "operation.failed"
  | "observation.recorded"
  | "evidence.recorded"
  | "experiment.completed"
  | "experiment.failed"
  | "compute.destroying"
  | "compute.destroyed";

export interface RuntimeEvent<T = unknown> {
  id: string;
  type: RuntimeEventType;
  experimentId: string;
  timestamp: string;
  payload: T;
  causationId?: string;
}

export interface Observation {
  id: string;
  operationId?: string;
  timestamp: string;
  source: string;
  data: unknown;
}

export interface EvidenceReference {
  id: string;
  kind: "file" | "network" | "process" | "log" | "artifact" | "other";
  uri: string;
  sha256?: string;
  metadata?: Record<string, unknown>;
}

export interface OperationRecord {
  operationId: string;
  capability: string;
  status: "proposed" | "pending-approval" | "running" | "succeeded" | "failed" | "denied";
  startedAt?: string;
  finishedAt?: string;
  error?: string;
}

export interface ResearchState {
  experimentId: string;
  phase: RuntimePhase;
  revision: number;
  activeIntentId?: string;
  observations: Observation[];
  evidence: EvidenceReference[];
  operations: OperationRecord[];
  events: RuntimeEvent[];
}

export function createResearchState(experimentId: string, now = new Date().toISOString()): ResearchState {
  const event: RuntimeEvent = {
    id: `evt-${cryptoRandomId()}`,
    type: "experiment.created",
    experimentId,
    timestamp: now,
    payload: { phase: "created" },
  };

  return {
    experimentId,
    phase: "created",
    revision: 0,
    observations: [],
    evidence: [],
    operations: [],
    events: [event],
  };
}

export function appendEvent<T>(state: ResearchState, event: RuntimeEvent<T>): ResearchState {
  if (event.experimentId !== state.experimentId) {
    throw new Error(`Event ${event.id} belongs to ${event.experimentId}, not ${state.experimentId}.`);
  }

  return {
    ...state,
    revision: state.revision + 1,
    events: [...state.events, event],
  };
}

export function transitionPhase(
  state: ResearchState,
  phase: RuntimePhase,
  eventType: RuntimeEventType,
  payload: unknown = {},
  now = new Date().toISOString(),
): ResearchState {
  return appendEvent(
    { ...state, phase },
    {
      id: `evt-${cryptoRandomId()}`,
      type: eventType,
      experimentId: state.experimentId,
      timestamp: now,
      payload,
    },
  );
}

function cryptoRandomId(): string {
  return Math.random().toString(36).slice(2, 10);
}
