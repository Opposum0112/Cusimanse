import assert from "node:assert/strict";
import test from "node:test";
import { AdapterRegistry } from "../src/adapters/index.js";
import { createCapabilityRegistry } from "../src/capabilities/index.js";
import { CARGateway } from "../src/integrations/crewai/server.js";
import type { CusimanseIR } from "../src/ir/index.js";
import { OperationEngine } from "../src/operations/index.js";
import { ApprovalManager, PolicyEngine } from "../src/policy/index.js";
import { RuntimeOrchestrator } from "../src/runtime/index.js";
import { createResearchState } from "../src/state/index.js";

const experimentId = "crewai-gateway-test";

function makeRuntime(executed: string[]) {
  const capabilities = createCapabilityRegistry([
    { name: "test.observe", version: "v1", operationKinds: ["evidence"] },
    { name: "test.denied", version: "v1", operationKinds: ["tool"] },
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
    capabilities: ["test.observe", "test.denied"],
    async execute(context) {
      executed.push(context.operationId);
      return { status: "succeeded", evidenceRefs: ["evidence://gateway-test"] };
    },
  });
  return new RuntimeOrchestrator({ capabilities, policy, approvals, operations, adapters });
}

function makeIr(): CusimanseIR {
  return {
    version: "v1",
    experimentId,
    source: { format: "json", path: "tests/crewai-gateway.test.ts" },
    intents: [],
  };
}

test("CrewAI proposal crosses gateway, policy, runtime, and adapter", async () => {
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

    const stateResponse = await fetch(`${baseUrl}/v1/research/${experimentId}/state`);
    assert.equal(stateResponse.status, 200);
    const returnedState = (await stateResponse.json()).state;
    assert.equal(returnedState.phase, "completed");
    assert.equal(returnedState.events.some((event: { type: string }) => event.type === "operation.succeeded"), true);

    const evidenceResponse = await fetch(`${baseUrl}/v1/research/${experimentId}/evidence`);
    assert.equal(evidenceResponse.status, 200);
    const evidence = (await evidenceResponse.json()).evidence;
    assert.equal(evidence.length, 1);
    assert.equal(evidence[0].uri, "evidence://gateway-test");
  } finally {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
});

test("policy denial stops a CrewAI proposal before the adapter", async () => {
  const executed: string[] = [];
  const gateway = new CARGateway(makeRuntime(executed));
  gateway.register({ ir: makeIr(), state: createResearchState(experimentId) });

  const result = await gateway.submitProposal({
    experimentId,
    proposal: { intent: "attempt a policy-denied operation", capability: "test.denied", parameters: {}, complete: false },
  });

  assert.equal(result.accepted, true);
  assert.equal(executed.length, 0);
  const state = await gateway.getState(experimentId);
  assert.equal(state.state.events.some((event) => event.type === "operation.proposed"), true);
  assert.equal(state.state.events.some((event) => event.type === "operation.succeeded"), false);
});

test("gateway rejects executable proposals without an explicit capability", async () => {
  const gateway = new CARGateway(makeRuntime([]));
  gateway.register({ ir: makeIr(), state: createResearchState(experimentId) });

  await assert.rejects(
    () => gateway.submitProposal({ experimentId, proposal: { intent: "not a capability", parameters: {}, complete: false } }),
    /Proposal capability is required/,
  );
});
