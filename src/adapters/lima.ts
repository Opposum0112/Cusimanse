export interface LimaProfile {
  name: string;
  cpus: number;
  memory: string;
  mounts?: string[];
}

export interface LimaProvider {
  create(profile: LimaProfile): Promise<void>;
  exec(vm: string, command: string, args?: string[]): Promise<{ stdout: string; stderr: string; exitCode: number }>;
  destroy(vm: string): Promise<void>;
}

export class LimaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "LimaError";
  }
}

const VM_NAME = /^[a-z][a-z0-9-]{1,32}$/;
const MEMORY = /^\d+(GiB|MiB)$/;

export function validateLimaProfile(profile: LimaProfile): LimaProfile {
  if (!VM_NAME.test(profile.name)) {
    throw new LimaError("Lima VM name must be lowercase alphanumeric with dashes, 2–33 characters.");
  }
  if (!Number.isInteger(profile.cpus) || profile.cpus < 1 || profile.cpus > 8) {
    throw new LimaError("Lima cpus must be an integer from 1 to 8.");
  }
  if (!MEMORY.test(profile.memory)) {
    throw new LimaError("Lima memory must look like 4GiB or 2048MiB.");
  }
  const mounts = profile.mounts ?? [];
  for (const mount of mounts) {
    if (typeof mount !== "string" || !mount.startsWith("/") || mount.includes("..")) {
      throw new LimaError("Lima mounts must be absolute paths without ...");
    }
  }
  return {
    name: profile.name,
    cpus: profile.cpus,
    memory: profile.memory,
    ...(mounts.length ? { mounts: [...mounts] } : {}),
  };
}

export function assertLimaProvider(provider: LimaProvider): void {
  if (typeof provider.create !== "function" || typeof provider.destroy !== "function" || typeof provider.exec !== "function") {
    throw new LimaError("Lima provider must implement create, exec, and destroy.");
  }
}

/** Create then destroy a validated profile. Use before attaching the provider to a live lab. */
export async function validateLimaProvider(
  provider: LimaProvider,
  profile: LimaProfile = { name: "car-lima-probe", cpus: 1, memory: "1GiB" },
): Promise<void> {
  assertLimaProvider(provider);
  const normalized = validateLimaProfile(profile);
  try {
    await provider.create(normalized);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new LimaError(`Lima provider failed to create ${normalized.name}: ${message}`);
  }
  try {
    await provider.destroy(normalized.name);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new LimaError(`Lima provider failed to destroy ${normalized.name}: ${message}`);
  }
}

export class LimaLifecycle {
  private created = new Set<string>();

  constructor(private readonly provider: LimaProvider) {
    assertLimaProvider(provider);
  }

  async create(profile: LimaProfile): Promise<void> {
    const normalized = validateLimaProfile(profile);
    await this.provider.create(normalized);
    this.created.add(normalized.name);
  }

  async destroy(vm: string): Promise<void> {
    if (!VM_NAME.test(vm)) throw new LimaError("VM name is required and must match the Lima name rule.");
    await this.provider.destroy(vm);
    this.created.delete(vm);
  }

  createdVms(): string[] {
    return [...this.created];
  }
}
