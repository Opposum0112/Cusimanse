import { describe, expect, it } from "node:test";
import { OperationEngine } from "../../src/operations/index.js";

describe("operation engine", () => {
  it("preserves pending approval", () => {
    const e = new OperationEngine();
    const op = { id: "o1", experimentId: "e1", intentId: "i1", kind: "vm", capability: "vm.create", parameters: {}, requiresApproval: true };
    e.register(op);
    expect(e.authorize(op, false)).toBe("pending-approval");
    expect(e.approve(op.id)).toBe("running");
    expect(e.succeed(op.id)).toBe("succeeded");
  });

  it("rejects invalid transitions", () => {
    const e = new OperationEngine();
    const op = { id: "o1", experimentId: "e1", intentId: "i1", kind: "shell", capability: "shell.exec", parameters: {}, requiresApproval: false };
    e.register(op);
    e.authorize(op, true);
    e.succeed(op.id);
    expect(() => e.fail(op.id)).toThrow();
  });
});
