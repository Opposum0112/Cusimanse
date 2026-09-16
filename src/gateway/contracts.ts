import type { ReasoningProposal } from "../llm/index.js";
import type { ResearchState } from "../state/index.js";

export interface OperatorProposalRequest {
  experimentId: string;
  proposal: ReasoningProposal;
}

export interface OperatorStateResponse {
  experimentId: string;
  state: ResearchState;
}

export interface OperatorEvidenceResponse {
  experimentId: string;
  evidence: ResearchState["evidence"];
}

export interface OperatorIntentResponse {
  experimentId: string;
  accepted: boolean;
  proposal: ReasoningProposal;
}

/** Harness-neutral operator ABI. Any agent runtime may implement this. */
export interface OperatorPort {
  submitProposal(request: OperatorProposalRequest): Promise<OperatorIntentResponse>;
  getState(experimentId: string): Promise<OperatorStateResponse>;
  getEvidence(experimentId: string): Promise<OperatorEvidenceResponse>;
}
