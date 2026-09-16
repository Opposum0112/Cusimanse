import type { CompiledIR } from "../../ir/types.js";
import type { ComputeProvider } from "../../adapters/compute/types.js";
import type { ExecutionArtifacts, RuntimeTelemetry } from "../../evidence/types.js";

export interface RuntimeContext {
  runId: string;
  ir: CompiledIR;
  compute: ComputeProvider;
  onStepProgress?: (stepId: string, status: "pending" | "running" | "completed" | "failed") => void;
}
export interface ExecutionResult { success: boolean; durationMs: number; telemetry: RuntimeTelemetry; artifacts: ExecutionArtifacts; error?: Error; }
export interface ExperimentRuntime { readonly id: string; execute(ctx: RuntimeContext): Promise<ExecutionResult>; pause?(runId: string): Promise<void>; resume?(runId: string): Promise<void>; abort(runId: string): Promise<void>; }
