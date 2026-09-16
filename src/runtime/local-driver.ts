import type { ExperimentRuntime, RuntimeContext, ExecutionResult } from "./spi/types.js";
import type { RuntimeTelemetry } from "../evidence/types.js";

export class InMemoryRuntime implements ExperimentRuntime {
  readonly id = "local" as const;
  private aborted = new Set<string>();
  async execute(ctx: RuntimeContext): Promise<ExecutionResult> {
    const started = Date.now(); const events: RuntimeTelemetry["events"] = []; const references: string[] = []; let success = true; let failure: Error | undefined;
    await ctx.compute.createSandbox({ id: ctx.runId, image: ctx.ir.contract.scope?.compute?.profile ?? "default", cpus: 2, memoryMb: 2048, networkIsolation: "airgap" });
    try {
      for (const intent of ctx.ir.intents) {
        if (this.aborted.has(ctx.runId)) throw new Error(`Run aborted: ${ctx.runId}`);
        events.push({ timestamp: new Date().toISOString(), stepId: intent.id, status: "running" }); ctx.onStepProgress?.(intent.id, "running");
        const commandValue = intent.parameters.command; const command = typeof commandValue === "string" ? commandValue : "true";
        const argsValue = intent.parameters.args; const args = Array.isArray(argsValue) ? argsValue.filter((value): value is string => typeof value === "string") : [];
        const result = await ctx.compute.exec(command, args);
        if (result.exitCode !== 0) { success = false; failure = new Error(result.stderr || `Step ${intent.id} exited with ${result.exitCode}`); events.push({ timestamp: new Date().toISOString(), stepId: intent.id, status: "failed", detail: failure.message }); ctx.onStepProgress?.(intent.id, "failed"); break; }
        references.push(`evidence://${ctx.ir.experimentId}/${intent.id}`); events.push({ timestamp: new Date().toISOString(), stepId: intent.id, status: "completed" }); ctx.onStepProgress?.(intent.id, "completed");
      }
    } catch (error) { success = false; failure = error instanceof Error ? error : new Error("Runtime execution failed."); } finally { await ctx.compute.destroy(); }
    return { success, durationMs: Date.now() - started, telemetry: { runId: ctx.runId, events }, artifacts: { references }, ...(failure === undefined ? {} : { error: failure }) };
  }
  async abort(runId: string): Promise<void> { this.aborted.add(runId); }
}
