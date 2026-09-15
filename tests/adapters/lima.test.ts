import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { LimaLifecycle } from "../../src/adapters/lima.js";

describe("lima lifecycle", () => {
  it("delegates validated profiles and destruction", async () => {
    const calls: string[] = [];
    const provider = {
      create: async () => { calls.push("create"); },
      exec: async () => ({ stdout: "", stderr: "", exitCode: 0 }),
      destroy: async () => { calls.push("destroy"); },
    };
    const lifecycle = new LimaLifecycle(provider);
    await lifecycle.create({ name: "research", cpus: 2, memory: "4GiB" });
    await lifecycle.destroy("research");
    assert.deepEqual(calls, ["create", "destroy"]);
  });

  it("rejects invalid profiles", async () => {
    const lifecycle = new LimaLifecycle({ create: async () => {}, exec: async () => ({ stdout: "", stderr: "", exitCode: 0 }), destroy: async () => {} });
    await assert.rejects(lifecycle.create({ name: "", cpus: 0, memory: "" }));
  });
});
