import { describe, expect, it } from "node:test";
import { AdapterRegistry } from "../../src/adapters/index.js";

describe("adapter registry", () => {
  it("resolves registered capabilities without executing", () => {
    const registry = new AdapterRegistry();
    const adapter = { name: "fake", capabilities: ["x.run"], execute: async () => ({ status: "succeeded", evidenceRefs: [] }) };
    registry.register(adapter);
    expect(registry.resolve("x.run")).toBe(adapter);
  });
  it("rejects capability collisions", () => {
    const registry = new AdapterRegistry();
    registry.register({ name: "a", capabilities: ["x.run"], execute: async () => ({ status: "succeeded", evidenceRefs: [] }) });
    expect(() => registry.register({ name: "b", capabilities: ["x.run"], execute: async () => ({ status: "succeeded", evidenceRefs: [] }) })).toThrow();
  });
});
