import { describe, expect, it } from "vitest";
import { FailClosedToolApproval } from "../../src/policy/approval.js";
import { PolicyEngine } from "../../src/policy/index.js";

describe("fail-closed tool approval", () => {
  it("denies an operation without an explicit rule", () => {
    const approval = new FailClosedToolApproval(new PolicyEngine([]));
    expect(approval.evaluate("dangerous.tool", {})).toBe("denied");
  });
  it("maps approval-required to user approval", () => {
    const approval = new FailClosedToolApproval(new PolicyEngine([{ id: "r1", capability: "x", decision: "approval-required", reason: "operator review" }]));
    expect(approval.evaluate("x", {})).toBe("user-approval");
  });
});
