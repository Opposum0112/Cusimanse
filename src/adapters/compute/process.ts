import type { ComputeProvider, ExecResult, SandboxSpec } from "./types.js";
import { spawn } from "node:child_process";

export abstract class ProcessComputeProvider implements ComputeProvider {
  abstract readonly id: ComputeProvider["id"];
  protected sandboxId: string | undefined;
  protected spec: SandboxSpec | undefined;
  protected abstract binary(): string;
  protected abstract availableArgs(): string[];
  protected abstract createArgs(spec: SandboxSpec): string[];
  protected abstract execArgs(cmd: string, args: string[]): string[];
  protected abstract copyArgs(hostSrc: string, guestDst: string): string[];
  protected abstract extractArgs(guestSrc: string, hostDst: string): string[];
  protected abstract destroyArgs(): string[];

  async isAvailable(): Promise<boolean> {
    return await this.probe(this.binary(), this.availableArgs());
  }
  async createSandbox(spec: SandboxSpec): Promise<void> {
    this.spec = spec;
    this.sandboxId = spec.id;
    await this.run(this.binary(), this.createArgs(spec));
  }
  async exec(cmd: string, args: string[] = []): Promise<ExecResult> {
    this.requireSandbox();
    return await this.run(this.binary(), this.execArgs(cmd, args));
  }
  async copyToSandbox(hostSrc: string, guestDst: string): Promise<void> {
    this.requireSandbox();
    await this.run(this.binary(), this.copyArgs(hostSrc, guestDst));
  }
  async extractArtifacts(guestSrc: string, hostDst: string): Promise<void> {
    this.requireSandbox();
    await this.run(this.binary(), this.extractArgs(guestSrc, hostDst));
  }
  async destroy(): Promise<void> {
    if (this.sandboxId !== undefined) await this.run(this.binary(), this.destroyArgs());
    this.sandboxId = undefined;
    this.spec = undefined;
  }
  protected requireSandbox(): string {
    if (!this.sandboxId) throw new Error(`${this.id} sandbox has not been created.`);
    return this.sandboxId;
  }
  protected async run(binary: string, args: string[]): Promise<ExecResult> {
    const started = Date.now();
    return await new Promise<ExecResult>((resolve, reject) => {
      const child = spawn(binary, args, { shell: false });
      let stdout = "";
      let stderr = "";
      child.stdout.setEncoding("utf8"); child.stderr.setEncoding("utf8");
      child.stdout.on("data", (chunk: string) => { stdout += chunk; });
      child.stderr.on("data", (chunk: string) => { stderr += chunk; });
      child.on("error", reject);
      child.on("close", (exitCode) => resolve({ exitCode: exitCode ?? 1, stdout, stderr, durationMs: Date.now() - started }));
    });
  }
  private async probe(binary: string, args: string[]): Promise<boolean> {
    try { return (await this.run(binary, args)).exitCode === 0; } catch { return false; }
  }
}
