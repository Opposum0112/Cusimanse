import test from "node:test";
import assert from "node:assert/strict";
import { CapabilityRegistry } from "../../src/capabilities/index.js";
import { PolicyEngine, ApprovalManager } from "../../src/policy/index.js";
import { OperationEngine } from "../../src/operations/index.js";
import { AdapterRegistry, type Adapter } from "../../src/adapters/index.js";
import { RuntimeOrchestrator } from "../../src/runtime/index.js";
import { createResearchState } from "../../src/state/index.js";

test("runtime executes an allowed operation", async () => {
  let calls = 0;
  const capabilities = new CapabilityRegistry();
  capabilities.register({ name: "workload.npm.install", version: "1", operationKinds: ["tool"] });
  const adapters = new AdapterRegistry();
  const adapter: Adapter = { name: "npm", capabilities: ["workload.npm.install"], execute: async () => { calls++; return { status: "succeeded", evidenceRefs: [] }; } };
  adapters.register(adapter);
  const runtime = new RuntimeOrchestrator({ capabilities, adapters, policy: new PolicyEngine([{ id: "allow", capability: "workload.npm.install", decision: "allow", reason: "test" }]), approvals: new ApprovalManager(), operations: new OperationEngine() });
  const ir = { version: "v1" as const, experimentId: "exp", source: { format: "yaml" as const, path: "x" }, intents: [{ id: "i", capability: "workload.npm.install", parameters: {}, dependsOn: [] }] };
  const result = await runtime.run(ir, createResearchState("exp"));
  assert.equal(calls, 1); assert.equal(result.executedOperationIds.length, 1); assert.equal(result.state.phase, "completed");
});

test("approval-required blocks adapter execution", async () => {
  let calls = 0;
  const capabilities = new CapabilityRegistry(); capabilities.register({ name: "vm.create", version: "1", operationKinds: ["vm"] });
  const adapters = new AdapterRegistry(); adapters.register({ name: "vm", capabilities: ["vm.create"], execute: async () => { calls++; return { status: "succeeded", evidenceRefs: [] }; } });
  const runtime = new RuntimeOrchestrator({ capabilities, adapters, policy: new PolicyEngine([{ id: "approval", capability: "vm.create", decision: "approval-required", reason: "human approval" }]), approvals: new ApprovalManager(), operations: new OperationEngine() });
  const ir = { version: "v1" as const, experimentId: "exp", source: { format: "yaml" as const, path: "x" }, intents: [{ id: "i", capability: "vm.create", parameters: {}, dependsOn: [] }] };
  const result = await runtime.run(ir, createResearchState("exp"));
  assert.equal(calls, 0); assert.equal(result.pendingApprovalIds.length, 1); assert.equal(result.state.phase, "awaiting-approval");
});
