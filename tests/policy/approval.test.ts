import { describe, expect, it } from "node:test";
import { ApprovalManager, PolicyEngine } from "../../src/policy/index.js";

describe("policy", () => {
  const context = { experimentId: "e1", intentId: "i1", capability: "vm.create", operationKind: "vm", parameters: {} };

  it("defaults to deny", () => {
    expect(new PolicyEngine([]).evaluate(context).decision).toBe("deny");
  });

  it("returns the deterministic matching rule", () => {
    const engine = new PolicyEngine([
      { id: "z", capability: "vm.create", decision: "deny", reason: "z" },
      { id: "a", capability: "vm.create", decision: "approval-required", reason: "approval" },
    ]);
    expect(engine.evaluate(context).decision).toBe("approval-required");
    expect(engine.evaluate(context).ruleId).toBe("a");
  });

  it("keeps approval pending until explicitly decided", () => {
    const approvals = new ApprovalManager();
    const request = approvals.request(context);
    expect(request.status).toBe("pending");
    expect(approvals.grant(request.id, "operator").status).toBe("granted");
    expect(() => approvals.grant(request.id, "operator")).toThrow();
  });
});
