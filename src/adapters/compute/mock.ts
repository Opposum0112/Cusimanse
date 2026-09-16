import type { ComputeProvider, ExecResult, SandboxSpec } from "./types.js";
export class MockComputeProvider implements ComputeProvider {
  readonly id = "mock" as const;
  private created = false;
  private spec: SandboxSpec | undefined;
  readonly transfers: Array<{ direction: "to" | "from"; source: string; destination: string }> = [];
  async isAvailable(): Promise<boolean> { return true; }
  async createSandbox(spec: SandboxSpec): Promise<void> { this.spec = spec; this.created = true; }
  async exec(cmd: string, args: string[] = []): Promise<ExecResult> { if (!this.created) throw new Error("Mock sandbox has not been created."); const started = Date.now(); const command = [cmd, ...args].join(" "); if (command.includes("__mock_fail__")) return { exitCode: 1, stdout: "", stderr: "mock failure", durationMs: Date.now() - started }; return { exitCode: 0, stdout: JSON.stringify({ sandbox: this.spec?.id, command: cmd, args }), stderr: "", durationMs: Date.now() - started }; }
  async copyToSandbox(hostSrc: string, guestDst: string): Promise<void> { if (!this.created) throw new Error("Mock sandbox has not been created."); this.transfers.push({ direction: "to", source: hostSrc, destination: guestDst }); }
  async extractArtifacts(guestSrc: string, hostDst: string): Promise<void> { if (!this.created) throw new Error("Mock sandbox has not been created."); this.transfers.push({ direction: "from", source: guestSrc, destination: hostDst }); }
  async destroy(): Promise<void> { this.created = false; this.spec = undefined; }
}
