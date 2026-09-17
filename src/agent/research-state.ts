export type HypothesisStatus = "open" | "supported" | "rejected";
export type VerificationStatus = "unverified" | "verified";

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
  hypotheses: ResearchHypothesis[];
  findings: ResearchFinding[];
  observations: unknown[];
  evidenceIds: string[];
  iteration: number;
  maxIterations: number;
}

export function createAutonomousResearchState(objectiveId: string, maxIterations = 12): AutonomousResearchState {
  return { objectiveId, hypotheses: [], findings: [], observations: [], evidenceIds: [], iteration: 0, maxIterations };
}

export function recordObservation(state: AutonomousResearchState, observation: unknown): AutonomousResearchState {
  return { ...state, observations: [...state.observations, observation], iteration: state.iteration + 1 };
}

export function recordEvidence(state: AutonomousResearchState, evidenceId: string): AutonomousResearchState {
  if (state.evidenceIds.includes(evidenceId)) return state;
  return { ...state, evidenceIds: [...state.evidenceIds, evidenceId] };
}

export function shouldTerminate(state: AutonomousResearchState): boolean {
  if (state.iteration >= state.maxIterations) return true;
  return state.findings.length > 0 && state.findings.every((finding) => finding.verification === "verified");
}
