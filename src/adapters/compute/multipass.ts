import { access } from "node:fs/promises";
import { runProcess } from "./process.js";
import type { ComputeProvider, ExecResult, SandboxSpec } from "./types.js";

export class MultipassComputeProvider implements ComputeProvider {
  readonly id = "multipass" as const;
  private name?: string;
  async isAvailable(): Promise<boolean> { return (await runProcess("multipass", ["version"])).exitCode === 0; }
  async createSandbox(spec: SandboxSpec): Promise<void> {
    this.name = spec.id;
    const args = ["launch", spec.image, "--name", spec.id];
    if (spec.cpus > 0) args.push("--cpus", String(spec.cpus));
    if (spec.memoryMb > 0) args.push("--memory", `${spec.memoryMb}M`);
    const result = await runProcess("multipass", args);
    if (result.exitCode !== 0) throw new Error(`Multipass launch failed: ${result.stderr}`);
  }
  async exec(cmd: string, args: string[] = []): Promise<ExecResult> {
    if (!this.name) throw new Error("Multipass sandbox has not been created.");
    return runProcess("multipass", ["exec", this.name, "--", cmd, ...args]);
  }
  async copyToSandbox(hostSrc: string, guestDst: string): Promise<void> {
    if (!this.name) throw new Error("Multipass sandbox has not been created.");
    await access(hostSrc);
    const result = await runProcess("multipass", ["transfer", hostSrc, `${this.name}:${guestDst}`]);
    if (result.exitCode !== 0) throw new Error(`Multipass transfer failed: ${result.stderr}`);
  }
  async extractArtifacts(guestSrc: string, hostDst: string): Promise<void> {
    if (!this.name) throw new Error("Multipass sandbox has not been created.");
    const result = await runProcess("multipass", ["transfer", `${this.name}:${guestSrc}`, hostDst]);
    if (result.exitCode !== 0) throw new Error(`Multipass artifact extraction failed: ${result.stderr}`);
  }
  async destroy(): Promise<void> {
    if (!this.name) return;
    await runProcess("multipass", ["delete", this.name]);
    await runProcess("multipass", ["purge"]);
    this.name = undefined;
  }
}
