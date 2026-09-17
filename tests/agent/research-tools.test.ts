import { describe, expect, it, vi } from "vitest";
import { createGovernedResearchTools } from "../../src/agent/research-tools.js";
import { FailClosedToolApproval } from "../../src/policy/approval.js";
import type { ComputeProvider } from "../../src/adapters/compute/types.js";
import type { ExperimentRuntime } from "../../src/runtime/spi/types.js";

const compute: ComputeProvider = {
  id: "mock",
  isAvailable: async () => true,
  createSandbox: vi.fn(async () => undefined),
  exec: vi.fn(async () => ({ exitCode: 0, stdout: "ok", stderr: "", durationMs: 1 })),
  copyToSandbox: vi.fn(async () => undefined),
  extractArtifacts: vi.fn(async () => undefined),
  destroy: vi.fn(async () => undefined),
};
const runtime = {} as ExperimentRuntime;
const objective = { id: "objective-1", question: "test" };

describe("governed research tools", () => {
  it("executes typed workload through the compute SPI", async () => {
    const tools = createGovernedResearchTools({ runId: "run-1", traceId: "trace-1", objective, compute, runtime });
    const result = await tools.execute_workload.execute({ experimentId: "exp-1", intentId: "intent-1", command: "npm", args: ["--version"] });
    expect(result).toMatchObject({ success: true, exitCode: 0 });
    expect(compute.exec).toHaveBeenCalledWith("npm", ["--version"]);
  });

  it("fails closed when policy denies a tool", async () => {
    const policy = { evaluate: () => ({ decision: "deny", reason: "blocked" }) } as never;
    const events: Array<{ status: string }> = [];
    const approval = new FailClosedToolApproval(policy, audit => events.push({ status: audit.decision }));
    const tools = createGovernedResearchTools({ runId: "run-1", traceId: "trace-1", objective, compute, runtime, approval, emit: event => events.push({ status: event.status }) });

    await expect(tools.execute_workload.execute({ experimentId: "exp-1", intentId: "intent-1", command: "npm", args: [] })).rejects.toThrow(/policy denied/);
    expect(compute.exec).not.toHaveBeenCalled();
    expect(events.some(event => event.status === "denied")).toBe(true);
  });
});
