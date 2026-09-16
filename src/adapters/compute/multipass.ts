import { ProcessComputeProvider } from "./process.js";
import type { SandboxSpec } from "./types.js";

export class MultipassComputeProvider extends ProcessComputeProvider {
  readonly id = "multipass" as const;
  protected binary(): string { return "multipass"; }
  protected availableArgs(): string[] { return ["version"]; }
  protected createArgs(spec: SandboxSpec): string[] { return ["launch", spec.image, "--name", spec.id, "--cpus", String(spec.cpus), "--memory", `${spec.memoryMb}M`]; }
  protected execArgs(cmd: string, args: string[]): string[] { return ["exec", this.requireSandbox(), "--", cmd, ...args]; }
  protected copyArgs(hostSrc: string, guestDst: string): string[] { return ["transfer", hostSrc, `${this.requireSandbox()}:${guestDst}`]; }
  protected extractArgs(guestSrc: string, hostDst: string): string[] { return ["transfer", `${this.requireSandbox()}:${guestSrc}`, hostDst]; }
  protected destroyArgs(): string[] { return ["delete", this.requireSandbox(), "--purge"]; }
}
