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

export interface OperatorSessionRequest {
  recipe: unknown;
}

export interface OperatorSessionResponse {
  experimentId: string;
  state: ResearchState;
}

/** Harness-neutral operator ABI. Any agent runtime may implement this. */
export interface OperatorPort {
  submitProposal(request: OperatorProposalRequest): Promise<OperatorIntentResponse>;
  getState(experimentId: string): Promise<OperatorStateResponse>;
  getEvidence(experimentId: string): Promise<OperatorEvidenceResponse>;
}

/** Optional lifecycle extension used by the generic Cusimanse MCP server. */
export interface ResearchSessionPort extends OperatorPort {
  createResearchSession(request: OperatorSessionRequest): Promise<OperatorSessionResponse>;
  completeResearch(experimentId: string): Promise<OperatorStateResponse>;
}
