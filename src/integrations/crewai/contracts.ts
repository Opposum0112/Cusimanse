import type { ReasoningProposal } from "../../llm/index.js";
import type { ResearchState } from "../../state/index.js";

export interface CrewAIProposalRequest {
  experimentId: string;
  proposal: ReasoningProposal;
}

export interface CrewAIStateResponse {
  experimentId: string;
  state: ResearchState;
}

export interface CrewAIEvidenceResponse {
  experimentId: string;
  evidence: ResearchState["evidence"];
}

export interface CrewAIIntentResponse {
  experimentId: string;
  accepted: boolean;
  proposal: ReasoningProposal;
}

export interface CrewAIResearchPort {
  submitProposal(request: CrewAIProposalRequest): Promise<CrewAIIntentResponse>;
  getState(experimentId: string): Promise<CrewAIStateResponse>;
  getEvidence(experimentId: string): Promise<CrewAIEvidenceResponse>;
}
