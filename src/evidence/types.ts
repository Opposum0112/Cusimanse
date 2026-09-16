export interface RuntimeTelemetry { runId: string; events: Array<{ timestamp: string; stepId: string; status: "pending" | "running" | "completed" | "failed"; detail?: string }>; }
export interface ExecutionArtifacts { references: string[]; }
