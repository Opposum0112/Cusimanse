import { access } from "node:fs/promises";
import { runProcess } from "./process.js";
import type { ComputeProvider, ExecResult, SandboxSpec } from "./types.js";

export class LimaComputeProvider implements ComputeProvider {
  readonly id = "lima" as const;
  private name: string | undefined;
  async isAvailable(): Promise<boolean> { return (await runProcess("limactl", ["--version"])).exitCode === 0; }
  async createSandbox(spec: SandboxSpec): Promise<void> {
    this.name = spec.id;
    const args = ["create", "--name", spec.id];
    if (spec.cpus > 0) args.push("--cpus", String(spec.cpus));
    if (spec.memoryMb > 0) args.push("--memory", `${Math.ceil(spec.memoryMb / 1024)}GiB`);
    args.push(spec.image);
    const result = await runProcess("limactl", args);
    if (result.exitCode !== 0) throw new Error(`Lima create failed: ${result.stderr}`);
    const start = await runProcess("limactl", ["start", spec.id]);
    if (start.exitCode !== 0) throw new Error(`Lima start failed: ${start.stderr}`);
  }
  async exec(cmd: string, args: string[] = []): Promise<ExecResult> {
    if (!this.name) throw new Error("Lima sandbox has not been created.");
    return runProcess("limactl", ["shell", this.name, "--", cmd, ...args]);
  }
  async copyToSandbox(hostSrc: string, guestDst: string): Promise<void> {
    if (!this.name) throw new Error("Lima sandbox has not been created.");
    await access(hostSrc);
    const result = await runProcess("limactl", ["copy", hostSrc, `${this.name}:${guestDst}`]);
    if (result.exitCode !== 0) throw new Error(`Lima copy failed: ${result.stderr}`);
  }
  async extractArtifacts(guestSrc: string, hostDst: string): Promise<void> {
    if (!this.name) throw new Error("Lima sandbox has not been created.");
    const result = await runProcess("limactl", ["copy", `${this.name}:${guestSrc}`, hostDst]);
    if (result.exitCode !== 0) throw new Error(`Lima artifact extraction failed: ${result.stderr}`);
  }
  async destroy(): Promise<void> {
    if (!this.name) return;
    await runProcess("limactl", ["delete", "--force", this.name]);
    this.name = undefined;
  }
}
