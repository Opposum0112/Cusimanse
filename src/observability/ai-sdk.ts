import type { ResearchTracer } from "./types.js";

export function createAISDKTelemetry(tracer: ResearchTracer, runId: string, traceId: string): { isEnabled: boolean; record: (name: string, data?: unknown, durationMs?: number) => void } {
  return {
    isEnabled: true,
    record: (name, data, durationMs) => tracer.emit({ runId, traceId, kind: "model", name, timestamp: new Date().toISOString(), ...(durationMs === undefined ? {} : { durationMs }), ...(data === undefined ? {} : { data }) })
  };
}
