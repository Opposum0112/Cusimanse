export const STRACE_CAPABILITY = "instrumentation.strace";
export const SYSDIG_CAPABILITY = "instrumentation.sysdig";

export const STRACE_ALLOWED_TARGETS = ["npm", "node", "workload"] as const;
export type StraceTarget = (typeof STRACE_ALLOWED_TARGETS)[number];

export interface StraceRequest {
  target: StraceTarget;
  durationSeconds: number;
  outputPath: string;
}

export interface SysdigRequest {
  durationSeconds: number;
  outputPath: string;
  /** Named capture profile only — not a free-form Sysdig filter string from the operator. */
  profile: "process" | "network" | "file";
}

export class InstrumentationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InstrumentationError";
  }
}

export function parseStraceRequest(parameters: Record<string, unknown>): StraceRequest {
  const target = parameters.target;
  if (target !== "npm" && target !== "node" && target !== "workload") {
    throw new InstrumentationError("strace target must be npm, node, or workload.");
  }
  const durationSeconds = numberInRange(parameters.durationSeconds ?? parameters.duration, 1, 120, "strace durationSeconds");
  const outputPath = scopedPath(parameters.outputPath, "strace outputPath");
  return { target, durationSeconds, outputPath };
}

export function parseSysdigRequest(parameters: Record<string, unknown>): SysdigRequest {
  const profile = parameters.profile;
  if (profile !== "process" && profile !== "network" && profile !== "file") {
    throw new InstrumentationError("sysdig profile must be process, network, or file.");
  }
  const durationSeconds = numberInRange(parameters.durationSeconds ?? parameters.duration, 1, 120, "sysdig durationSeconds");
  const outputPath = scopedPath(parameters.outputPath, "sysdig outputPath");
  return { profile, durationSeconds, outputPath };
}

function numberInRange(value: unknown, min: number, max: number, label: string): number {
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n) || n < min || n > max) {
    throw new InstrumentationError(`${label} must be a number between ${min} and ${max}.`);
  }
  return n;
}

function scopedPath(value: unknown, label: string): string {
  if (typeof value !== "string" || !value.startsWith("/workspace/") || value.includes("..")) {
    throw new InstrumentationError(`${label} must be a path under /workspace/.`);
  }
  return value;
}
