import type { ComputeProvider, ExecResult, SandboxSpec } from "./types.js";

export interface RemoteSandboxDriver {
  create(spec: SandboxSpec): Promise<void>;
  exec(cmd: string, args: string[]): Promise<ExecResult>;
  copyToSandbox(hostSrc: string, guestDst: string): Promise<void>;
  extractArtifacts(guestSrc: string, hostDst: string): Promise<void>;
  destroy(): Promise<void>;
  isAvailable(): Promise<boolean>;
}

export class DelegatingComputeProvider implements ComputeProvider {
  constructor(readonly id: "firecracker" | "cloud", private readonly driver: RemoteSandboxDriver) {}
  isAvailable(): Promise<boolean> { return this.driver.isAvailable(); }
  createSandbox(spec: SandboxSpec): Promise<void> { return this.driver.create(spec); }
  exec(cmd: string, args: string[] = []): Promise<ExecResult> { return this.driver.exec(cmd, args); }
  copyToSandbox(hostSrc: string, guestDst: string): Promise<void> { return this.driver.copyToSandbox(hostSrc, guestDst); }
  extractArtifacts(guestSrc: string, hostDst: string): Promise<void> { return this.driver.extractArtifacts(guestSrc, hostDst); }
  destroy(): Promise<void> { return this.driver.destroy(); }
}
