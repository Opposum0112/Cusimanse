import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { LimaLifecycle, validateLimaProfile, validateLimaProvider, LimaError } from "../../src/adapters/lima.js";

function memoryProvider() {
  const vms = new Set<string>();
  return {
    vms,
    create: async (profile: { name: string }) => { vms.add(profile.name); },
    exec: async () => ({ stdout: "", stderr: "", exitCode: 0 }),
    destroy: async (vm: string) => {
      if (!vms.has(vm)) throw new Error(`unknown vm ${vm}`);
      vms.delete(vm);
    },
  };
}

describe("lima lifecycle", () => {
  it("delegates validated profiles and destruction", async () => {
    const provider = memoryProvider();
    const lifecycle = new LimaLifecycle(provider);
    await lifecycle.create({ name: "research", cpus: 2, memory: "4GiB" });
    assert.deepEqual(lifecycle.createdVms(), ["research"]);
    await lifecycle.destroy("research");
    assert.deepEqual(lifecycle.createdVms(), []);
    assert.equal(provider.vms.size, 0);
  });

  it("rejects invalid profiles before create", async () => {
    const lifecycle = new LimaLifecycle(memoryProvider());
    await assert.rejects(lifecycle.create({ name: "", cpus: 0, memory: "" }), LimaError);
    assert.throws(() => validateLimaProfile({ name: "OK", cpus: 2, memory: "4GiB" }), LimaError);
    assert.throws(() => validateLimaProfile({ name: "research", cpus: 64, memory: "4GiB" }), LimaError);
  });

  it("validateLimaProvider creates then destroys", async () => {
    const provider = memoryProvider();
    await validateLimaProvider(provider, { name: "car-lima-probe", cpus: 1, memory: "1GiB" });
    assert.equal(provider.vms.size, 0);
  });

  it("validateLimaProvider fails when destroy is broken", async () => {
    const provider = {
      create: async () => {},
      exec: async () => ({ stdout: "", stderr: "", exitCode: 0 }),
      destroy: async () => { throw new Error("limactl delete failed"); },
    };
    await assert.rejects(validateLimaProvider(provider), /failed to destroy/);
  });
});
