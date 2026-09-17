import { tool, type ToolSet } from "ai";
import { z } from "zod";
import type { ComputeProvider } from "../adapters/compute/types.js";
import type { ExperimentRuntime } from "../runtime/spi/types.js";
import type { FailClosedToolApproval } from "../policy/approval.js";
import type { ResearchObjective } from "./types.js";

export interface ResearchToolDependencies {
  runId: string;
  traceId: string;
  objective: ResearchObjective;
  compute: ComputeProvider;
  runtime: ExperimentRuntime;
  approval?: FailClosedToolApproval;
  emit?: (event: ResearchToolEvent) => void;
}

export interface ResearchToolEvent {
  runId: string;
  traceId: string;
  tool: string;
  status: "started" | "completed" | "denied" | "failed";
  timestamp: string;
  data?: Record<string, unknown>;
}

const base = {
  experimentId: z.string().default("unknown"),
  intentId: z.string().default("unknown"),
};

function guarded(deps: ResearchToolDependencies, toolName: string, input: unknown): void {
  if (!deps.approval) return;
  const decision = deps.approval.evaluate(toolName, input);
  if (decision !== "approved") {
    deps.emit?.({ runId: deps.runId, traceId: deps.traceId, tool: toolName, status: "denied", timestamp: new Date().toISOString(), data: { decision } });
    throw new Error(`Cusimanse policy denied tool ${toolName}: ${decision}`);
  }
}

function lifecycle(deps: ResearchToolDependencies, tool: string, status: ResearchToolEvent["status"], data?: Record<string, unknown>): void {
  deps.emit?.({ runId: deps.runId, traceId: deps.traceId, tool, status, timestamp: new Date().toISOString(), ...(data ? { data } : {}) });
}

export function createGovernedResearchTools(deps: ResearchToolDependencies): ToolSet {
  return {
    create_lab: tool({
      description: "Create the disposable research lab described by an approved sandbox specification.",
      inputSchema: z.object({ ...base, id: z.string().min(1), image: z.string().min(1), cpus: z.number().int().positive(), memoryMb: z.number().int().positive(), networkIsolation: z.enum(["airgap", "dns-only", "full"]), guestProbeBinary: z.string().optional() }),
      execute: async (input) => {
        lifecycle(deps, "create_lab", "started");
        try {
          guarded(deps, "create_lab", input);
          await deps.compute.createSandbox({ id: input.id, image: input.image, cpus: input.cpus, memoryMb: input.memoryMb, networkIsolation: input.networkIsolation, ...(input.guestProbeBinary ? { guestProbeBinary: input.guestProbeBinary } : {}) });
          lifecycle(deps, "create_lab", "completed", { sandboxId: input.id });
          return { success: true, sandboxId: input.id };
        } catch (error) {
          lifecycle(deps, "create_lab", "failed", { error: error instanceof Error ? error.message : String(error) });
          throw error;
        }
      },
    }),
    execute_workload: tool({
      description: "Execute an approved workload through the Cusimanse runtime; no arbitrary shell is exposed.",
      inputSchema: z.object({ ...base, command: z.string().min(1), args: z.array(z.string()).default([]) }),
      execute: async (input) => {
        lifecycle(deps, "execute_workload", "started");
        try {
          guarded(deps, "execute_workload", input);
          const result = await deps.compute.exec(input.command, input.args);
          const output = { success: result.exitCode === 0, exitCode: result.exitCode, stdout: result.stdout, stderr: result.stderr, durationMs: result.durationMs };
          lifecycle(deps, "execute_workload", "completed", { exitCode: result.exitCode, durationMs: result.durationMs });
          return output;
        } catch (error) {
          lifecycle(deps, "execute_workload", "failed", { error: error instanceof Error ? error.message : String(error) });
          throw error;
        }
      },
    }),
    observe_network: tool({
      description: "Record an observation request for the active research lab. Network capture integration is supplied by the runtime adapter.",
      inputSchema: z.object({ ...base, filter: z.string().optional(), durationSeconds: z.number().int().positive().max(3600).default(30) }),
      execute: async (input) => {
        guarded(deps, "observe_network", input);
        const observation = { observed: false, filter: input.filter ?? "", durationSeconds: input.durationSeconds, reason: "No network observer is attached to this runtime." };
        lifecycle(deps, "observe_network", "completed", observation);
        return observation;
      },
    }),
    query_telemetry: tool({
      description: "Query runtime telemetry through a governed adapter; never fabricates telemetry.",
      inputSchema: z.object({ ...base, query: z.string().min(1) }),
      execute: async (input) => {
        guarded(deps, "query_telemetry", input);
        const result = { observed: false, query: input.query, reason: "No telemetry query adapter is attached to this runtime." };
        lifecycle(deps, "query_telemetry", "completed", result);
        return result;
      },
    }),
    inspect_artifact: tool({
      description: "Inspect a previously materialized artifact by copying it from the isolated lab.",
      inputSchema: z.object({ ...base, guestPath: z.string().min(1), hostPath: z.string().min(1) }),
      execute: async (input) => {
        guarded(deps, "inspect_artifact", input);
        await deps.compute.extractArtifacts(input.guestPath, input.hostPath);
        const result = { success: true, guestPath: input.guestPath, hostPath: input.hostPath };
        lifecycle(deps, "inspect_artifact", "completed", result);
        return result;
      },
    }),
    verify_finding: tool({
      description: "Record a verification request without treating an unverified claim as evidence.",
      inputSchema: z.object({ ...base, findingId: z.string().min(1), evidenceRefs: z.array(z.string()).default([]) }),
      execute: async (input) => {
        guarded(deps, "verify_finding", input);
        const result = { verified: false, findingId: input.findingId, evidenceRefs: input.evidenceRefs, reason: "Verification requires a configured verifier adapter." };
        lifecycle(deps, "verify_finding", "completed", result);
        return result;
      },
    }),
    destroy_lab: tool({
      description: "Destroy the active disposable research lab.",
      inputSchema: z.object({ ...base, reason: z.string().min(1) }),
      execute: async (input) => {
        lifecycle(deps, "destroy_lab", "started");
        try {
          guarded(deps, "destroy_lab", input);
          await deps.compute.destroy();
          lifecycle(deps, "destroy_lab", "completed", { reason: input.reason });
          return { success: true };
        } catch (error) {
          lifecycle(deps, "destroy_lab", "failed", { error: error instanceof Error ? error.message : String(error) });
          throw error;
        }
      },
    }),
  };
}
