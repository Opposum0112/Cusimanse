export {
  addFinding,
  addHypothesis,
  applyResearchEvent,
  createAutonomousResearchState,
  recordEvidence,
  recordObservation,
  shouldTerminate,
  transitionPhase,
  updateHypothesisStatus,
  verifyFinding,
} from "../state/research.js";

export type {
  AutonomousResearchState,
  HypothesisStatus,
  ResearchEvent,
  ResearchFinding,
  ResearchHypothesis,
  ResearchPhase,
  VerificationStatus,
} from "../state/research.js";
