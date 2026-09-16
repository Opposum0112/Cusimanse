import { ProcessComputeProvider } from "./process.js";
import type { SandboxSpec } from "./types.js";

export class LimaComputeProvider extends ProcessComputeProvider {
  readonly id = "lima" as const;
  protected binary(): string { return "limactl"; }
  protected availableArgs(): string[] { return ["version"]; }
  protected createArgs(spec: SandboxSpec): string[] { return ["start", spec.id, "--name", spec.id]; }
  protected execArgs(cmd: string, args: string[]): string[] { return ["shell", this.requireSandbox(), "--", cmd, ...args]; }
  protected copyArgs(hostSrc: string, guestDst: string): string[] { return ["copy", hostSrc, `${this.requireSandbox()}:${guestDst}`]; }
  protected extractArgs(guestSrc: string, hostDst: string): string[] { return ["copy", `${this.requireSandbox()}:${guestSrc}`, hostDst]; }
  protected destroyArgs(): string[] { return ["stop", this.requireSandbox(), "--force"]; }
}
