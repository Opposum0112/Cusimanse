import {
  applyResearchEvent,
  createAutonomousResearchState,
  type AutonomousResearchState,
  type ResearchEvent,
} from "./research.js";
import { EvidenceJournal, createEvidenceId, type EvidenceRecord } from "./evidence.js";

export type { AutonomousResearchState, HypothesisStatus, ResearchEvent, ResearchFinding, ResearchHypothesis, ResearchPhase, VerificationStatus } from "./research.js";
export { addFinding, addHypothesis, applyResearchEvent, createAutonomousResearchState, recordEvidence, recordObservation, shouldTerminate, transitionPhase as transitionResearchPhase, updateHypothesisStatus, verifyFinding } from "./research.js";
export { EvidenceJournal, createEvidenceId } from "./evidence.js";
export type { EvidenceRecord } from "./evidence.js";

export type RuntimePhase = "created" | "planning" | "awaiting-approval" | "executing" | "observing" | "completed" | "failed" | "destroying";
export type RuntimeEventType = "experiment.created" | "intent.planned" | "operation.proposed" | "approval.requested" | "approval.granted" | "approval.denied" | "operation.started" | "operation.succeeded" | "operation.failed" | "observation.recorded" | "evidence.recorded" | "experiment.completed" | "experiment.failed" | "compute.destroying" | "compute.destroyed";

export interface RuntimeEvent<T = unknown> { id: string; type: RuntimeEventType; experimentId: string; timestamp: string; payload: T; causationId?: string; sequence: number; }
export interface ResearchEventEnvelope { id: string; type: "research"; experimentId: string; timestamp: string; payload: ResearchEvent; causationId?: string; sequence: number; }
export type CusimanseEvent = RuntimeEvent | ResearchEventEnvelope;
export interface Observation { id: string; operationId?: string; timestamp: string; source: string; data: unknown; }
export interface EvidenceReference { id: string; kind: "file" | "network" | "process" | "log" | "artifact" | "other"; uri: string; sha256?: string; metadata?: Record<string, unknown>; }
export interface OperationRecord { operationId: string; capability: string; status: "proposed" | "pending-approval" | "running" | "succeeded" | "failed" | "denied"; startedAt?: string; finishedAt?: string; error?: string; }

export interface ResearchState { experimentId: string; phase: RuntimePhase; revision: number; activeIntentId?: string; observations: Observation[]; evidence: EvidenceReference[]; operations: OperationRecord[]; events: RuntimeEvent[]; }
export interface CusimanseResearchState { experiment: ResearchState; autonomous: AutonomousResearchState; events: CusimanseEvent[]; revision: number; }

export function createResearchState(experimentId: string, now = new Date().toISOString()): ResearchState {
  const event: RuntimeEvent = { id: `evt-${cryptoRandomId()}`, type: "experiment.created", experimentId, timestamp: now, payload: { phase: "created" }, sequence: 0 };
  return { experimentId, phase: "created", revision: 0, observations: [], evidence: [], operations: [], events: [event] };
}

export function createCusimanseResearchState(experimentId: string, objectiveId = experimentId, maxIterations = 12, now = new Date().toISOString()): CusimanseResearchState {
  const experiment = createResearchState(experimentId, now);
  return { experiment, autonomous: createAutonomousResearchState(objectiveId, maxIterations), events: [{ id: experiment.events[0]!.id, type: "research", experimentId, timestamp: now, payload: { type: "phase.changed", phase: "planning" }, sequence: 0 }], revision: 0 };
}

export function appendEvent<T>(state: ResearchState, event: RuntimeEvent<T>): ResearchState {
  if (event.experimentId !== state.experimentId) throw new Error(`Event ${event.id} belongs to ${event.experimentId}, not ${state.experimentId}.`);
  if (event.sequence !== state.revision + 1) throw new Error(`Invalid event sequence: expected ${state.revision + 1}, received ${event.sequence}.`);
  return { ...state, revision: event.sequence, events: [...state.events, event] };
}

export function appendAggregateResearchEvent(state: CusimanseResearchState, event: ResearchEvent, now = new Date().toISOString(), causationId?: string): CusimanseResearchState {
  const autonomous = applyResearchEvent(state.autonomous, event);
  const sequence = state.revision + 1;
  const envelope: ResearchEventEnvelope = { id: `evt-${cryptoRandomId()}`, type: "research", experimentId: state.experiment.experimentId, timestamp: now, payload: event, causationId, sequence };
  return { ...state, autonomous, events: [...state.events, envelope], revision: sequence };
}

export function appendAggregateRuntimeEvent<T>(state: CusimanseResearchState, event: RuntimeEvent<T>): CusimanseResearchState {
  if (event.experimentId !== state.experiment.experimentId) throw new Error(`Event ${event.id} belongs to ${state.experiment.experimentId}.`);
  if (event.sequence !== state.revision + 1) throw new Error(`Invalid aggregate event sequence: expected ${state.revision + 1}, received ${event.sequence}.`);
  return { ...state, experiment: appendEvent(state.experiment, event), events: [...state.events, event], revision: event.sequence };
}

export function appendResearchObservation(state: CusimanseResearchState, observation: unknown, now = new Date().toISOString(), causationId?: string): CusimanseResearchState {
  return appendAggregateResearchEvent(state, { type: "observation.recorded", observation }, now, causationId);
}

export function appendResearchEvidence(state: CusimanseResearchState, evidenceId: string, now = new Date().toISOString(), causationId?: string): CusimanseResearchState {
  return appendAggregateResearchEvent(state, { type: "evidence.recorded", evidenceId }, now, causationId);
}

export function transitionPhase(state: ResearchState, phase: RuntimePhase, eventType: RuntimeEventType, payload: unknown = {}, now = new Date().toISOString()): ResearchState {
  return appendEvent({ ...state, phase }, { id: `evt-${cryptoRandomId()}`, type: eventType, experimentId: state.experimentId, timestamp: now, payload, sequence: state.revision + 1 });
}

export function applyAutonomousResearchEvent(state: CusimanseResearchState, event: ResearchEvent): CusimanseResearchState {
  return appendAggregateResearchEvent(state, event);
}

function cryptoRandomId(): string { return Math.random().toString(36).slice(2, 10); }
