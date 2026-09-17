import { describe, expect, it, vi } from "vitest";
import { createGovernedResearchTools } from "../../src/agent/research-tools.js";
import { FailClosedToolApproval } from "../../src/policy/approval.js";
import { createCapabilityRegistry } from "../../src/capabilities/index.js";
import { createAutonomousResearchState } from "../../src/state/research.js";
import { createResearchStateStore } from "../../src/state/store.js";
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

const createStore = () => createResearchStateStore(createAutonomousResearchState(objective.id));

describe("governed research tools", () => {
  it("executes typed workload through the compute SPI", async () => {
    const tools = createGovernedResearchTools({ runId: "run-1", traceId: "trace-1", objective, compute, runtime });
    const result = await tools.execute_workload.execute({ experimentId: "exp-1", intentId: "intent-1", command: "npm", args: ["--version"] });
    expect(result).toMatchObject({ success: true, exitCode: 0 });
    expect(compute.exec).toHaveBeenCalledWith("npm", ["--version"]);
  });

  it("resolves the declared capability and records observation/evidence in the state store", async () => {
    const stateStore = createStore();
    const capabilities = createCapabilityRegistry([
      { name: "execute_workload", version: "1.0.0", operationKinds: ["workload.execute"] },
    ]);
    const tools = createGovernedResearchTools({ runId: "run-2", traceId: "trace-2", objective, compute, runtime, capabilityRegistry: capabilities, evidenceJournal: new (await import("../../src/state/evidence.js")).EvidenceJournal(), stateStore });

    const result = await tools.execute_workload.execute({ experimentId: "exp-1", intentId: "intent-1", command: "npm", args: ["--version"] });
    expect(result).toMatchObject({ success: true, evidenceId: "evidence:run-2:0:execute_workload" });
    expect(stateStore.get().state.observations).toHaveLength(1);
    expect(stateStore.get().state.evidenceIds).toEqual(["evidence:run-2:0:execute_workload"]);
    expect(stateStore.get().revision).toBe(2);
  });

  it("fails closed when an explicitly supplied capability registry cannot resolve a tool", async () => {
    const capabilities = createCapabilityRegistry([]);
    const events: Array<{ status: string }> = [];
    const tools = createGovernedResearchTools({ runId: "run-3", traceId: "trace-3", objective, compute, runtime, capabilityRegistry: capabilities, emit: event => events.push({ status: event.status }) });

    await expect(tools.execute_workload.execute({ experimentId: "exp-1", intentId: "intent-1", command: "npm", args: [] })).rejects.toThrow(/Capability not registered/);
    expect(compute.exec).not.toHaveBeenCalled();
    expect(events.some(event => event.status === "denied")).toBe(false);
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
