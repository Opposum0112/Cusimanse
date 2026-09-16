import { describe, expect, it } from "vitest";
import { MockComputeProvider } from "../../src/adapters/compute/mock.js";
import { getComputeProvider } from "../../src/adapters/compute/factory.js";

describe("compute provider SPI", () => {
  it("provides a hermetic mock", async () => {
    const provider = await getComputeProvider("mock");
    expect(provider).toBeInstanceOf(MockComputeProvider);
    await provider.createSandbox({ id: "test", image: "default", cpus: 1, memoryMb: 128, networkIsolation: "airgap" });
    expect((await provider.exec("printf", ["ok"])).exitCode).toBe(0);
    await provider.destroy();
  });
  it("rejects unknown providers", async () => { await expect(getComputeProvider("unknown")).rejects.toThrow("Unknown compute provider"); });
});
