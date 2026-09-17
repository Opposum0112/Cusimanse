import type { ResearchTracer } from "./types.js";

export function createAISDKTelemetry(tracer: ResearchTracer, runId: string, traceId: string, experimentId?: string) {
  const emit = (kind: "agent" | "model" | "tool", name: string, data?: unknown, durationMs?: number): void => {
    tracer.emit({ runId, traceId, ...(experimentId === undefined ? {} : { experimentId }), kind, name, timestamp: new Date().toISOString(), ...(durationMs === undefined ? {} : { durationMs }), ...(data === undefined ? {} : { data }) });
  };
  return {
    emitModelStart: (data: unknown): void => emit("model", "model.start", data),
    emitToolStart: (data: unknown): void => emit("tool", "tool.start", data),
    emitToolFinish: (data: unknown, durationMs: number): void => emit("tool", "tool.finish", data, durationMs),
    emitStep: (data: unknown): void => emit("agent", "agent.step", data),
    emitEnd: (data: unknown): void => emit("agent", "agent.end", data),
  };
}
