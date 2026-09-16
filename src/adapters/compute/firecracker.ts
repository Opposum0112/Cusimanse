import type { ComputeProvider, ExecResult, SandboxSpec } from "./types.js";
export class FirecrackerComputeProvider implements ComputeProvider {
  readonly id: string = "firecracker";
  private delegate: ComputeProvider | undefined;
  constructor(delegate?: ComputeProvider) { this.delegate = delegate; }
  async isAvailable(): Promise<boolean> { return this.delegate ? await this.delegate.isAvailable() : false; }
  private requireDelegate(): ComputeProvider { if (!this.delegate) throw new Error("Firecracker/cloud provider is not configured. Supply a Firecracker ComputeProvider adapter."); return this.delegate; }
  async createSandbox(spec: SandboxSpec): Promise<void> { await this.requireDelegate().createSandbox(spec); }
  async exec(cmd: string, args: string[] = []): Promise<ExecResult> { return await this.requireDelegate().exec(cmd, args); }
  async copyToSandbox(hostSrc: string, guestDst: string): Promise<void> { await this.requireDelegate().copyToSandbox(hostSrc, guestDst); }
  async extractArtifacts(guestSrc: string, hostDst: string): Promise<void> { await this.requireDelegate().extractArtifacts(guestSrc, hostDst); }
  async destroy(): Promise<void> { await this.requireDelegate().destroy(); }
}
export class CloudComputeProvider extends FirecrackerComputeProvider { override readonly id: string = "cloud"; }
