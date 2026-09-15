import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { ApprovalManager, PolicyEngine } from "../../src/policy/index.js";

describe("policy", () => {
  const context = { experimentId: "e1", intentId: "i1", capability: "vm.create", operationKind: "vm", parameters: {} };

  it("defaults to deny", () => {
    assert.equal(new PolicyEngine([]).evaluate(context).decision, "deny");
  });

  it("returns the deterministic matching rule", () => {
    const engine = new PolicyEngine([
      { id: "z", capability: "vm.create", decision: "deny", reason: "z" },
      { id: "a", capability: "vm.create", decision: "approval-required", reason: "approval" },
    ]);
    assert.equal(engine.evaluate(context).decision, "approval-required");
    assert.equal(engine.evaluate(context).ruleId, "a");
  });

  it("keeps approval pending until explicitly decided", () => {
    const approvals = new ApprovalManager();
    const request = approvals.request(context);
    assert.equal(request.status, "pending");
    assert.equal(approvals.grant(request.id, "operator").status, "granted");
    assert.throws(() => approvals.grant(request.id, "operator"));
  });
});
