import type { LanguageModel } from "ai";
import { generateText, Output } from "ai";
import { z } from "zod";
import type { Reasoner, ReasoningResult, RuntimeState } from "../runtime/index.js";

const proposalSchema = z.object({
  intent: z.string().min(1),
  capability: z.string().min(1).optional(),
  parameters: z.record(z.string(), z.unknown()).optional(),
  complete: z.boolean(),
});

export interface VercelAIReasonerOptions {
  model: LanguageModel;
  system?: string;
}

export class VercelAIReasoner implements Reasoner {
  constructor(private readonly options: VercelAIReasonerOptions) {}

  async reason(state: RuntimeState): Promise<ReasoningResult> {
    const result = await generateText({
      model: this.options.model,
      system: this.options.system ??
        "You are the reasoning layer of Cusimanse Agent Runtime. Propose research intent only. Never assume authorization, credentials, host access, policy changes, or approval.",
      output: Output.object({
        name: "CusimanseReasoning",
        description: "A proposed next research intent for CAR to validate.",
        schema: proposalSchema,
      }),
      prompt: JSON.stringify(state),
    });
    return result.output;
  }
}
