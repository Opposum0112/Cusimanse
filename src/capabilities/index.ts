export interface CapabilityDescriptor<TParameters = Record<string, unknown>> {
  name: string;
  version: string;
  operationKinds: string[];
  description?: string;
  validateParameters?: (parameters: Record<string, unknown>) => void;
  metadata?: Record<string, unknown>;
}

export interface ResolvedCapability<TParameters = Record<string, unknown>> {
  descriptor: CapabilityDescriptor<TParameters>;
  parameters: TParameters;
}

export class CapabilityResolutionError extends Error {
  constructor(message: string, readonly issues: string[] = []) {
    super(message);
    this.name = "CapabilityResolutionError";
  }
}

export class CapabilityRegistry {
  private readonly capabilities = new Map<string, CapabilityDescriptor>();

  register(descriptor: CapabilityDescriptor): void {
    if (!descriptor.name) throw new CapabilityResolutionError("Capability name is required.");
    if (this.capabilities.has(descriptor.name)) {
      throw new CapabilityResolutionError(`Capability already registered: ${descriptor.name}`);
    }
    this.capabilities.set(descriptor.name, descriptor);
  }

  resolve<TParameters = Record<string, unknown>>(
    name: string,
    parameters: Record<string, unknown> = {},
  ): ResolvedCapability<TParameters> {
    const descriptor = this.capabilities.get(name);
    if (!descriptor) {
      throw new CapabilityResolutionError(`Capability not registered: ${name}`, [
        `unresolved capability: ${name}`,
      ]);
    }

    descriptor.validateParameters?.(parameters);
    return {
      descriptor: descriptor as CapabilityDescriptor<TParameters>,
      parameters: parameters as TParameters,
    };
  }

  has(name: string): boolean {
    return this.capabilities.has(name);
  }

  list(): CapabilityDescriptor[] {
    return [...this.capabilities.values()].sort((a, b) => a.name.localeCompare(b.name));
  }
}

export function createCapabilityRegistry(
  descriptors: CapabilityDescriptor[] = [],
): CapabilityRegistry {
  const registry = new CapabilityRegistry();
  for (const descriptor of descriptors) registry.register(descriptor);
  return registry;
}
