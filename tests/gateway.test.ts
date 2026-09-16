import assert from "node:assert/strict";
import test from "node:test";
import { AdapterRegistry } from "../src/adapters/index.js";
import { createCapabilityRegistry } from "../src/capabilities/index.js";
import { CARGateway } from "../src/gateway/server.js";
import type { CusimanseIR } from "../src/ir/index.js";
import { OperationEngine } from "../src/operations/index.js";
import { ApprovalManager, PolicyEngine } from "../src/policy/index.js";
import { RuntimeOrchestrator } from "../src/runtime/index.js";
import { createResearchState } from "../src/state/index.js";
import { LabError, createLab } from "../src/lab/index.js";

const experimentId = "operator-gateway-test";

function makeRuntime(executed: string[]) {
  const capabilities = createCapabilityRegistry([
    { name: "test.observe", version: "v1", operationKinds: ["evidence"] },
    { name: "test.denied", version: "v1", operationKinds: ["tool"] },
    { name: "host.shell", version: "v1", operationKinds: ["shell"] },
  ]);
  const policy = new PolicyEngine([
    {
      id: "allow-test-observe",
      capability: "test.observe",
      operationKind: "evidence",
      decision: "allow",
      reason: "Gateway integration test allow rule.",
    },
  ]);
  const approvals = new ApprovalManager();
  const operations = new OperationEngine();
  const adapters = new AdapterRegistry();
  adapters.register({
    name: "test-adapter",
    capabilities: ["test.observe", "test.denied", "host.shell"],
    async execute(context) {
      executed.push(context.operationId);
      return { status: "succeeded", evidenceRefs: ["evidence://gateway-test"] };
    },
  });
  return new RuntimeOrchestrator({ capabilities, policy, approvals, operations, adapters });
}

function makeIr(allowedCapabilities?: string[]): CusimanseIR {
  const ir: CusimanseIR = {
    version: "v1",
    experimentId,
    source: { format: "json", path: "tests/gateway.test.ts" },
    intents: [],
    contract: {
      contractVersion: "0.2",
      operationKinds: [],
      evidenceRequired: [],
      stopWhen: { allEvidenceRequired: false },
    },
  };
  if (allowedCapabilities) ir.contract.allowedCapabilities = allowedCapabilities;
  return ir;
}

test("operator proposal crosses gateway, policy, runtime, and adapter", async () => {
  const executed: string[] = [];
  const gateway = new CARGateway(makeRuntime(executed));
  const state = createResearchState(experimentId);
  state.evidence.push({ id: "ev-seeded", kind: "artifact", uri: "evidence://gateway-test", metadata: { source: "test-adapter" } });
  gateway.register({ ir: makeIr(), state });

  const server = gateway.listen({ host: "127.0.0.1", port: 0 });
  await new Promise<void>((resolve) => server.once("listening", resolve));
  const address = server.address();
  assert.ok(address && typeof address === "object");
  const baseUrl = `http://127.0.0.1:${address.port}`;

  try {
    const proposalResponse = await fetch(`${baseUrl}/v1/research/${experimentId}/proposals`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ proposal: { intent: "collect a controlled observation", capability: "test.observe", parameters: { source: "fixture" }, complete: false } }),
    });
    assert.equal(proposalResponse.status, 200);
    assert.equal((await proposalResponse.json()).accepted, true);
    assert.equal(executed.length, 1);
  } finally {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
});

test("policy denial stops an operator proposal before the adapter", async () => {
  const executed: string[] = [];
  const gateway = new CARGateway(makeRuntime(executed));
  gateway.register({ ir: makeIr(), state: createResearchState(experimentId) });

  const result = await gateway.submitProposal({
    experimentId,
    proposal: { intent: "attempt a policy-denied operation", capability: "test.denied", parameters: {}, complete: false },
  });

  assert.equal(result.accepted, true);
  assert.equal(executed.length, 0);
});

test("gateway rejects executable proposals without an explicit capability", async () => {
  const gateway = new CARGateway(makeRuntime([]));
  gateway.register({ ir: makeIr(), state: createResearchState(experimentId) });

  await assert.rejects(
    () => gateway.submitProposal({ experimentId, proposal: { intent: "not a capability", parameters: {}, complete: false } }),
    /Proposal capability is required/,
  );
});

test("frozen allowlist blocks a capability even when an adapter exists", async () => {
  const executed: string[] = [];
  const gateway = new CARGateway(makeRuntime(executed));
  gateway.register({ ir: makeIr(["test.observe"]), state: createResearchState(experimentId) });

  const result = await gateway.submitProposal({
    experimentId,
    proposal: { intent: "escape the contract", capability: "host.shell", parameters: {}, complete: false },
  });

  assert.equal(result.accepted, true);
  assert.equal(executed.length, 0);
  const state = await gateway.getState(experimentId);
  const proposed = state.state.events.find((event) => event.type === "operation.proposed");
  assert.equal((proposed?.payload as { contract?: { code?: string } }).contract?.code, "not_in_contract_allowlist");
});

test("createLab requires an operator", () => {
  assert.throws(
    () =>
      createLab({
        contract: { api_version: "v1", kind: "ExperimentRecipe", experiment_id: "x", intents: [] },
        policy: [],
        capabilities: [],
        adapters: [],
      }),
    LabError,
  );
});
