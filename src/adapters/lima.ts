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

export class LimaLifecycle {
  constructor(private readonly provider: LimaProvider) {}

  async create(profile: LimaProfile): Promise<void> {
    if (!profile.name || profile.cpus < 1 || !profile.memory) throw new Error("Invalid Lima profile");
    await this.provider.create({ ...profile, mounts: profile.mounts ? [...profile.mounts] : undefined });
  }

  async destroy(vm: string): Promise<void> {
    if (!vm) throw new Error("VM name is required");
    await this.provider.destroy(vm);
  }
}
