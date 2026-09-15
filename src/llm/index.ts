import { generateText, Output, type LanguageModel } from "ai";
import { z } from "zod";
import type { ResearchState } from "../state/index.js";

export const reasoningProposalSchema = z.object({
  intent: z.string().min(1),
  capability: z.string().min(1).optional(),
  parameters: z.record(z.string(), z.unknown()).optional(),
  complete: z.boolean(),
}).strict();

export type ReasoningProposal = z.infer<typeof reasoningProposalSchema>;
export interface Reasoner { reason(state: ResearchState): Promise<ReasoningProposal>; }
export interface VercelAIReasonerOptions { model: LanguageModel; system?: string; }

export class VercelAIReasoner implements Reasoner {
  constructor(private readonly options: VercelAIReasonerOptions) {}
  async reason(state: ResearchState): Promise<ReasoningProposal> {
    const result = await generateText({
      model: this.options.model,
      system: this.options.system ?? "You are the proposal-only reasoning layer of Cusimanse Agent Runtime. Propose declarative research intent only. Never assume authorization, credentials, host access, policy changes, or approval. Never emit shell commands or direct execution instructions.",
      output: Output.object({ name: "CusimanseReasoningProposal", description: "A proposed next research intent for CAR to validate and authorize.", schema: reasoningProposalSchema }),
      prompt: JSON.stringify(state),
    });
    if (!result.output) throw new Error("Reasoning model returned no proposal.");
    return result.output;
  }
}
