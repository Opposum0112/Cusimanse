import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { AdapterRegistry } from "../../src/adapters/index.js";

describe("adapter registry", () => {
  it("resolves registered capabilities without executing", () => {
    const registry = new AdapterRegistry();
    const adapter = {
      name: "fake",
      capabilities: ["x.run"],
      execute: async () => ({ status: "succeeded" as const, evidenceRefs: [] }),
    };
    registry.register(adapter);
    assert.equal(registry.resolve("x.run"), adapter);
  });

  it("rejects capability collisions", () => {
    const registry = new AdapterRegistry();
    registry.register({ name: "a", capabilities: ["x.run"], execute: async () => ({ status: "succeeded" as const, evidenceRefs: [] }) });
    assert.throws(() => registry.register({ name: "b", capabilities: ["x.run"], execute: async () => ({ status: "succeeded" as const, evidenceRefs: [] }) }));
  });
});
