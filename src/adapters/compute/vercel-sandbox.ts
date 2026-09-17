import { Sandbox } from "@vercel/sandbox";
import { ComputeProviderError, type ComputeProvider, type ExecResult, type SandboxSpec } from "./types.js";

/** Vercel Sandbox implementation of the Cusimanse ComputeProvider SPI. */
export class VercelSandboxComputeProvider implements ComputeProvider {
  readonly id = "vercel-sandbox";
  private sandbox: Sandbox | undefined;

  async isAvailable(): Promise<boolean> {
    return Boolean(process.env.VERCEL_OIDC_TOKEN || process.env.VERCEL_TOKEN);
  }

  async createSandbox(spec: SandboxSpec): Promise<void> {
    if (this.sandbox) throw new ComputeProviderError("Vercel Sandbox is already active.");
    const runtime = spec.image.startsWith("vercel/sandbox/node:") ? "node24" : "ubuntu";
    this.sandbox = await Sandbox.create({ runtime });
  }

  async exec(cmd: string, args: string[] = []): Promise<ExecResult> {
    if (!this.sandbox) throw new ComputeProviderError("Vercel Sandbox has not been created.");
    const started = Date.now();
    const result = await this.sandbox.runCommand(cmd, args);
    return { exitCode: result.exitCode, stdout: await result.stdout(), stderr: await result.stderr(), durationMs: Date.now() - started };
  }

  async copyToSandbox(hostSrc: string, guestDst: string): Promise<void> {
    if (!this.sandbox) throw new ComputeProviderError("Vercel Sandbox has not been created.");
    const { readFile } = await import("node:fs/promises");
    await this.sandbox.writeFiles([{ path: guestDst, content: await readFile(hostSrc) }]);
  }

  async extractArtifacts(guestSrc: string, hostDst: string): Promise<void> {
    if (!this.sandbox) throw new ComputeProviderError("Vercel Sandbox has not been created.");
    const { writeFile } = await import("node:fs/promises");
    const content = await this.sandbox.readFileToBuffer({ path: guestSrc });
    if (!content) throw new ComputeProviderError(`Artifact not found: ${guestSrc}`);
    await writeFile(hostDst, content);
  }

  async destroy(): Promise<void> {
    if (!this.sandbox) return;
    await this.sandbox.stop();
    this.sandbox = undefined;
  }
}
