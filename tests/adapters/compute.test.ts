import test from "node:test";
import assert from "node:assert/strict";
import { ComputeProviderRegistry, MockComputeProvider } from "../../src/adapters/compute/index.js";

test("compute registry resolves mock provider", async () => {
  const registry = new ComputeProviderRegistry();
  const provider = new MockComputeProvider();
  registry.register(provider);
  assert.equal(registry.get("mock"), provider);
  await provider.createSandbox({ id: "test", image: "mock", cpus: 1, memoryMb: 256, networkIsolation: "airgap" });
  const result = await provider.exec("echo", ["hello"]);
  assert.equal(result.exitCode, 0);
  assert.match(result.stdout, /hello/);
  await provider.destroy();
});
