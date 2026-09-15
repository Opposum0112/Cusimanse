export interface AdapterContext {
  experimentId: string;
  operationId: string;
}

export interface AdapterExecutionResult {
  status: "succeeded" | "failed";
  output?: unknown;
  error?: string;
  evidenceRefs: string[];
}

export interface Adapter<TParameters = Record<string, unknown>> {
  readonly name: string;
  readonly capabilities: readonly string[];
  execute(context: AdapterContext, parameters: TParameters): Promise<AdapterExecutionResult>;
}

export class AdapterRegistry {
  private readonly adapters = new Map<string, Adapter>();
  private readonly capabilityOwners = new Map<string, string>();

  register(adapter: Adapter): void {
    if (this.adapters.has(adapter.name)) throw new Error(`Adapter already registered: ${adapter.name}`);
    for (const capability of adapter.capabilities) {
      if (this.capabilityOwners.has(capability)) throw new Error(`Capability already has adapter: ${capability}`);
    }
    this.adapters.set(adapter.name, adapter);
    for (const capability of adapter.capabilities) this.capabilityOwners.set(capability, adapter.name);
  }

  resolve(capability: string): Adapter {
    const adapterName = this.capabilityOwners.get(capability);
    if (!adapterName) throw new Error(`No adapter registered for capability: ${capability}`);
    return this.adapters.get(adapterName)!;
  }

  list(): Adapter[] { return [...this.adapters.values()].sort((a, b) => a.name.localeCompare(b.name)); }
}
