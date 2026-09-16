import type { ComputeProvider } from "./types.js";
import { MockComputeProvider } from "./mock.js";
import { LimaComputeProvider } from "./lima.js";
import { MultipassComputeProvider } from "./multipass.js";
import { CloudComputeProvider } from "./firecracker.js";

export async function getComputeProvider(providerId: string): Promise<ComputeProvider> {
  const provider: ComputeProvider = providerId === "mock"
    ? new MockComputeProvider()
    : providerId === "lima"
      ? new LimaComputeProvider()
      : providerId === "multipass"
        ? new MultipassComputeProvider()
        : providerId === "cloud" || providerId === "firecracker"
          ? new CloudComputeProvider()
          : (() => { throw new Error(`Unknown compute provider: ${providerId}`); })();
  if (!(await provider.isAvailable())) throw new Error(`Compute provider unavailable: ${providerId}`);
  return provider;
}

export { ComputeProviderRegistry } from "./index.js";
export { MockComputeProvider } from "./mock.js";
export { LimaComputeProvider } from "./lima.js";
export { MultipassComputeProvider } from "./multipass.js";
export { CloudComputeProvider, FirecrackerComputeProvider } from "./firecracker.js";
export * from "./types.js";
