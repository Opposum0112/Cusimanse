import type { ComputeProvider, ExecResult, SandboxSpec } from "./types.js";

export class MockComputeProvider implements ComputeProvider {
  readonly id = "mock" as const;
  private created = false;
  private spec: SandboxSpec | undefined;

  async isAvailable(): Promise<boolean> { return true; }

  async createSandbox(spec: SandboxSpec): Promise<void> {
    this.spec = spec;
    this.created = true;
  }

  async exec(cmd: string, args: string[] = []): Promise<ExecResult> {
    if (!this.created) throw new Error("Mock sandbox has not been created.");
    const started = Date.now();
    return {
      exitCode: 0,
      stdout: JSON.stringify({ sandbox: this.spec?.id, command: cmd, args }),
      stderr: "",
      durationMs: Date.now() - started,
    };
  }

  async copyToSandbox(_hostSrc: string, _guestDst: string): Promise<void> {
    if (!this.created) throw new Error("Mock sandbox has not been created.");
  }

  async extractArtifacts(_guestSrc: string, _hostDst: string): Promise<void> {
    if (!this.created) throw new Error("Mock sandbox has not been created.");
  }

  async destroy(): Promise<void> {
    this.created = false;
    this.spec = undefined;
  }
}
