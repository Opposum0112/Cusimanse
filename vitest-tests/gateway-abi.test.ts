import { describe, expect, it } from "vitest";
import { CARGateway } from "../src/gateway/server.js";

describe("Operator ABI gateway", () => {
  it("runs a compiled recipe through mock/local", async () => {
    const gateway = new CARGateway();
    const result = await gateway.runExperiment({ recipe: { api_version: "v1", kind: "ExperimentRecipe", experiment_id: "gateway-test", contract_version: "v1", scope: { compute: { provider: "mock", disposable: true } }, intents: [{ id: "step", capability: "test", parameters: {}, depends_on: [] }], operation_kinds: ["tool"], evidence_required: [], stop_when: { all_evidence_required: false } }, provider: "mock", runtime: "local" });
    expect(result.result.success).toBe(true);
    expect((await gateway.listProviders()).find((item) => item.id === "mock")?.available).toBe(true);
    expect((await gateway.inspectEvidence(result.runId)).telemetry?.runId).toBe(result.runId);
  });
});
