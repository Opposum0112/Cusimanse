import test from "node:test";
import assert from "node:assert/strict";
import { DisposableResearchWorkflow } from "../../src/runtime/workflow.js";
import { LimaLifecycle, type LimaProvider } from "../../src/adapters/lima.js";
import { CapabilityRegistry } from "../../src/capabilities/index.js";
import { PolicyEngine, ApprovalManager } from "../../src/policy/index.js";
import { OperationEngine } from "../../src/operations/index.js";
import { AdapterRegistry } from "../../src/adapters/index.js";
import { EvidenceCollector } from "../../src/evidence/index.js";

test("workflow destroys disposable compute even after runtime failure", async () => {
  const calls: string[] = [];
  const provider: LimaProvider = {
    create: async () => { calls.push("create"); },
    exec: async () => ({ stdout: "", stderr: "", exitCode: 0 }),
    destroy: async () => { calls.push("destroy"); },
  };
  const capabilities = new CapabilityRegistry(); capabilities.register({ name: "missing.adapter", version: "1", operationKinds: ["tool"] });
  const deps = { capabilities, adapters: new AdapterRegistry(), policy: new PolicyEngine([{ id: "allow", capability: "missing.adapter", decision: "allow", reason: "test" }]), approvals: new ApprovalManager(), operations: new OperationEngine() };
  const workflow = new DisposableResearchWorkflow(new LimaLifecycle(provider), deps);
  const ir = { version: "v1" as const, experimentId: "exp", source: { format: "yaml" as const, path: "x" }, intents: [{ id: "i", capability: "missing.adapter", parameters: {}, dependsOn: [] }] };
  await assert.rejects(() => workflow.run(ir, { limaProfile: { name: "test-vm", cpus: 1, memory: "1GiB" }, evidence: new EvidenceCollector("exp") }));
  assert.deepEqual(calls, ["create", "destroy"]);
});
