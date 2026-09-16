import type { ComputeProvider } from "./types.js";

export class ComputeProviderRegistry {
  private readonly providers = new Map<string, ComputeProvider>();
  register(provider: ComputeProvider): void {
    if (this.providers.has(provider.id)) throw new Error(`Compute provider already registered: ${provider.id}`);
    this.providers.set(provider.id, provider);
  }
  get(id: string): ComputeProvider {
    const provider = this.providers.get(id);
    if (!provider) throw new Error(`Compute provider not registered: ${id}`);
    return provider;
  }
  list(): ComputeProvider[] { return [...this.providers.values()].sort((a, b) => a.id.localeCompare(b.id)); }
}

export * from "./types.js";
export { MockComputeProvider } from "./mock.js";
export { LimaComputeProvider } from "./lima.js";
export { MultipassComputeProvider } from "./multipass.js";
export { DelegatingComputeProvider } from "./remote.js";
export type { RemoteSandboxDriver } from "./remote.js";
