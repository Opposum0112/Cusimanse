import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { OperationEngine } from "../../src/operations/index.js";

describe("operation engine", () => {
  it("preserves pending approval", () => {
    const e = new OperationEngine();
    const op = { id: "o1", experimentId: "e1", intentId: "i1", kind: "vm", capability: "vm.create", parameters: {}, requiresApproval: true };
    e.register(op);
    assert.equal(e.authorize(op, false), "pending-approval");
    assert.equal(e.approve(op.id), "running");
    assert.equal(e.succeed(op.id), "succeeded");
  });

  it("rejects invalid transitions", () => {
    const e = new OperationEngine();
    const op = { id: "o1", experimentId: "e1", intentId: "i1", kind: "shell", capability: "shell.exec", parameters: {}, requiresApproval: false };
    e.register(op);
    e.authorize(op, true);
    e.succeed(op.id);
    assert.throws(() => e.fail(op.id));
  });
});
