import { describe, expect, it } from "vitest";
import type { VercelResearchWorkflowInput } from "../../src/runtime/vercel/research-workflow.js";

describe("Vercel research workflow contract", () => {
  it("keeps the workflow input serializable", () => {
    const input: VercelResearchWorkflowInput = {
      objective: {
        id: "obj-001",
        question: "Investigate package installation behavior in the disposable lab.",
        scope: { packageManager: "npm" },
        constraints: { network: "dns-only" },
      },
      model: "openai/gpt-5.5",
      maxSteps: 8,
    };

    expect(JSON.parse(JSON.stringify(input))).toEqual(input);
    expect(Object.keys(input).sort()).toEqual(["maxSteps", "model", "objective"]);
  });
});
