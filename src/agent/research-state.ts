export type HypothesisStatus = "open" | "supported" | "rejected";
export type VerificationStatus = "unverified" | "verified";
export type ResearchPhase = "planning" | "hypothesizing" | "executing" | "observing" | "analyzing" | "verifying" | "replanning" | "completed";

export interface ResearchHypothesis {
  id: string;
  statement: string;
  status: HypothesisStatus;
  evidenceIds: string[];
}

export interface ResearchFinding {
  id: string;
  statement: string;
  hypothesisId?: string;
  evidenceIds: string[];
  verification: VerificationStatus;
}

export interface AutonomousResearchState {
  objectiveId: string;
  phase: ResearchPhase;
  hypotheses: ResearchHypothesis[];
  findings: ResearchFinding[];
  observations: unknown[];
  evidenceIds: string[];
  iteration: number;
  maxIterations: number;
}

export type ResearchEvent =
  | { type: "phase.changed"; phase: ResearchPhase }
  | { type: "observation.recorded"; observation: unknown }
  | { type: "evidence.recorded"; evidenceId: string }
  | { type: "hypothesis.proposed"; hypothesis: ResearchHypothesis }
  | { type: "hypothesis.status"; hypothesisId: string; status: HypothesisStatus; evidenceIds?: string[] }
  | { type: "finding.proposed"; finding: ResearchFinding }
  | { type: "finding.verified"; findingId: string; evidenceIds?: string[] };

export function createAutonomousResearchState(objectiveId: string, maxIterations = 12): AutonomousResearchState {
  if (!objectiveId.trim()) throw new Error("objectiveId is required");
  if (!Number.isInteger(maxIterations) || maxIterations < 1) throw new Error("maxIterations must be a positive integer");
  return { objectiveId, phase: "planning", hypotheses: [], findings: [], observations: [], evidenceIds: [], iteration: 0, maxIterations };
}

function requireNonEmpty(value: string, field: string): void {
  if (!value.trim()) throw new Error(`${field} is required`);
}

function uniqueIds(ids: string[]): string[] {
  return [...new Set(ids)];
}

function assertEvidenceKnown(state: AutonomousResearchState, evidenceIds: string[]): void {
  for (const evidenceId of evidenceIds) {
    requireNonEmpty(evidenceId, "evidenceId");
    if (!state.evidenceIds.includes(evidenceId)) throw new Error(`Unknown evidence: ${evidenceId}`);
  }
}

const allowedTransitions: Record<ResearchPhase, ResearchPhase[]> = {
  planning: ["hypothesizing", "executing", "completed"],
  hypothesizing: ["executing", "replanning"],
  executing: ["observing", "failed" as ResearchPhase],
  observing: ["analyzing"],
  analyzing: ["verifying", "replanning"],
  verifying: ["completed", "replanning"],
  replanning: ["planning", "hypothesizing", "executing", "completed"],
  completed: [],
};

export function transitionPhase(state: AutonomousResearchState, phase: ResearchPhase): AutonomousResearchState {
  if (state.phase === phase) return state;
  if (!allowedTransitions[state.phase].includes(phase)) throw new Error(`Invalid research phase transition: ${state.phase} -> ${phase}`);
  return { ...state, phase };
}

export function recordObservation(state: AutonomousResearchState, observation: unknown): AutonomousResearchState {
  if (state.iteration >= state.maxIterations) return state;
  return { ...state, observations: [...state.observations, observation], iteration: state.iteration + 1 };
}

export function recordEvidence(state: AutonomousResearchState, evidenceId: string): AutonomousResearchState {
  requireNonEmpty(evidenceId, "evidenceId");
  if (state.evidenceIds.includes(evidenceId)) return state;
  return { ...state, evidenceIds: [...state.evidenceIds, evidenceId] };
}

export function addHypothesis(state: AutonomousResearchState, hypothesis: ResearchHypothesis): AutonomousResearchState {
  requireNonEmpty(hypothesis.id, "hypothesis.id");
  requireNonEmpty(hypothesis.statement, "hypothesis.statement");
  if (state.hypotheses.some((item) => item.id === hypothesis.id)) throw new Error(`Hypothesis already exists: ${hypothesis.id}`);
  assertEvidenceKnown(state, hypothesis.evidenceIds);
  return { ...state, hypotheses: [...state.hypotheses, { ...hypothesis, evidenceIds: uniqueIds(hypothesis.evidenceIds) }] };
}

export function updateHypothesisStatus(state: AutonomousResearchState, hypothesisId: string, status: HypothesisStatus, evidenceIds: string[] = []): AutonomousResearchState {
  const hypothesis = state.hypotheses.find((item) => item.id === hypothesisId);
  if (!hypothesis) throw new Error(`Unknown hypothesis: ${hypothesisId}`);
  assertEvidenceKnown(state, evidenceIds);
  return { ...state, hypotheses: state.hypotheses.map((item) => item.id === hypothesisId ? { ...item, status, evidenceIds: uniqueIds([...item.evidenceIds, ...evidenceIds]) } : item) };
}

export function addFinding(state: AutonomousResearchState, finding: ResearchFinding): AutonomousResearchState {
  requireNonEmpty(finding.id, "finding.id");
  requireNonEmpty(finding.statement, "finding.statement");
  if (state.findings.some((item) => item.id === finding.id)) throw new Error(`Finding already exists: ${finding.id}`);
  if (finding.hypothesisId && !state.hypotheses.some((item) => item.id === finding.hypothesisId)) throw new Error(`Unknown hypothesis: ${finding.hypothesisId}`);
  assertEvidenceKnown(state, finding.evidenceIds);
  return { ...state, findings: [...state.findings, { ...finding, evidenceIds: uniqueIds(finding.evidenceIds) }] };
}

export function verifyFinding(state: AutonomousResearchState, findingId: string, evidenceIds: string[] = []): AutonomousResearchState {
  const finding = state.findings.find((item) => item.id === findingId);
  if (!finding) throw new Error(`Unknown finding: ${findingId}`);
  assertEvidenceKnown(state, evidenceIds);
  return { ...state, findings: state.findings.map((item) => item.id === findingId ? { ...item, verification: "verified", evidenceIds: uniqueIds([...item.evidenceIds, ...evidenceIds]) } : item) };
}

export function applyResearchEvent(state: AutonomousResearchState, event: ResearchEvent): AutonomousResearchState {
  switch (event.type) {
    case "phase.changed": return transitionPhase(state, event.phase);
    case "observation.recorded": return recordObservation(state, event.observation);
    case "evidence.recorded": return recordEvidence(state, event.evidenceId);
    case "hypothesis.proposed": return addHypothesis(state, event.hypothesis);
    case "hypothesis.status": return updateHypothesisStatus(state, event.hypothesisId, event.status, event.evidenceIds ?? []);
    case "finding.proposed": return addFinding(state, event.finding);
    case "finding.verified": return verifyFinding(state, event.findingId, event.evidenceIds ?? []);
  }
}

export function shouldTerminate(state: AutonomousResearchState): boolean {
  if (state.iteration >= state.maxIterations) return true;
  return state.findings.length > 0 && state.findings.every((finding) => finding.verification === "verified");
}
