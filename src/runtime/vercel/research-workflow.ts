import { WorkflowAgent, type ModelCallStreamPart } from "@ai-sdk/workflow";
import { isStepCount } from "ai";
import { getWritable } from "workflow";
import type { ResearchObjective } from "../../agent/types.js";

export interface VercelResearchWorkflowInput {
  objective: ResearchObjective;
  model: string;
  maxSteps?: number;
}

export interface VercelResearchWorkflowResult {
  objectiveId: string;
  status: "completed";
  model: string;
  maxSteps: number;
}

/**
 * Durable Vercel Workflow entrypoint for Cusimanse research.
 *
 * Only serializable research input crosses the workflow boundary. Cusimanse
 * capabilities, policy, compute, and evidence implementations remain outside
 * the model prompt and are introduced through workflow-safe tools in the next
 * migration increment.
 */
export async function runVercelResearchWorkflow(
  input: VercelResearchWorkflowInput,
): Promise<VercelResearchWorkflowResult> {
  "use workflow";

  const maxSteps = input.maxSteps ?? 12;
  if (!input.objective.id) throw new Error("Research objective id is required.");
  if (!input.objective.question) throw new Error("Research objective question is required.");
  if (!input.model.includes("/")) {
    throw new Error(`WorkflowAgent model must use provider/model form: ${input.model}`);
  }
  if (!Number.isSafeInteger(maxSteps) || maxSteps < 1) {
    throw new Error("maxSteps must be a positive safe integer.");
  }

  const agent = new WorkflowAgent({
    id: "cusimanse-research-agent",
    model: input.model,
    instructions: [
      "You are the Cusimanse autonomous security research agent.",
      "Reason about the research objective and prepare the next governed action.",
      "Cusimanse policy, capability resolution, isolation, and evidence rules are authoritative.",
      "Never invent observations, evidence, findings, or tool results.",
    ].join(" "),
    runtimeContext: {
      objectiveId: input.objective.id,
      scope: input.objective.scope ?? {},
      constraints: input.objective.constraints ?? {},
    },
  });

  const writable = getWritable<ModelCallStreamPart>();
  await agent.stream({
    messages: [{ role: "user", content: input.objective.question }],
    writable,
    stopWhen: isStepCount(maxSteps),
  });

  return {
    objectiveId: input.objective.id,
    status: "completed",
    model: input.model,
    maxSteps,
  };
}
