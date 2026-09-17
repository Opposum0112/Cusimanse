import { tool, type ToolSet } from "ai";
import { z } from "zod";
import type { ComputeProvider } from "../adapters/compute/types.js";
import type { ExperimentRuntime } from "../runtime/spi/types.js";
import { CapabilityRegistry, createCapabilityRegistry, type ResolvedCapability } from "../capabilities/index.js";
import type { FailClosedToolApproval } from "../policy/approval.js";
import { EvidenceJournal, createEvidenceId } from "../state/evidence.js";
import { appendResearchEvidence, appendResearchObservation, type CusimanseResearchState } from "../state/index.js";
import type { ResearchStateStore } from "../state/store.js";
import type { ResearchObjective } from "./types.js";

export interface ResearchToolDependencies {
  runId: string;
  traceId: string;
  objective: ResearchObjective;
  compute: ComputeProvider;
  runtime: ExperimentRuntime;
  approval?: FailClosedToolApproval;
  capabilityRegistry?: CapabilityRegistry;
  evidenceJournal?: EvidenceJournal;
  stateStore?: ResearchStateStore;
  /** @deprecated Prefer stateStore. Kept temporarily for compatibility with existing integrations. */
  state?: CusimanseResearchState;
  emit?: (event: ResearchToolEvent) => void;
}

export interface ResearchToolEvent {
  runId: string;
  traceId: string;
  tool: string;
  status: "started" | "completed" | "denied" | "failed";
  timestamp: string;
  evidenceId?: string;
  data?: Record<string, unknown>;
}

const base = { experimentId: z.string().default("unknown"), intentId: z.string().default("unknown") };

const defaultCapabilityRegistry = (): CapabilityRegistry => createCapabilityRegistry([
  { name: "create_lab", version: "1.0.0", operationKinds: ["lab.create"] },
  { name: "execute_workload", version: "1.0.0", operationKinds: ["workload.execute"] },
  { name: "observe_network", version: "1.0.0", operationKinds: ["network.observe"] },
  { name: "query_telemetry", version: "1.0.0", operationKinds: ["telemetry.query"] },
  { name: "inspect_artifact", version: "1.0.0", operationKinds: ["artifact.inspect"] },
  { name: "verify_finding", version: "1.0.0", operationKinds: ["finding.verify"] },
  { name: "destroy_lab", version: "1.0.0", operationKinds: ["lab.destroy"] },
]);

function resolveAndGuard<T extends Record<string, unknown>>(
  deps: ResearchToolDependencies,
  toolName: string,
  operationKind: string,
  input: T,
): ResolvedCapability<T> {
  const registry = deps.capabilityRegistry ?? defaultCapabilityRegistry();
  try {
    const resolved = registry.resolve<T>(toolName, input);
    if (!resolved.descriptor.operationKinds.includes(operationKind)) {
      throw new Error(`Capability ${toolName} does not permit operation ${operationKind}`);
    }
    guarded(deps, toolName, { ...input, capability: resolved.descriptor.name, operationKind, parameters: input });
    return resolved;
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    if (reason.startsWith("Cusimanse policy denied tool")) throw error;
    deps.emit?.({
      runId: deps.runId,
      traceId: deps.traceId,
      tool: toolName,
      status: "denied",
      timestamp: new Date().toISOString(),
      data: { reason, capability: toolName, operationKind },
    });
    throw error;
  }
}

function guarded(deps: ResearchToolDependencies, toolName: string, input: unknown): void {
  if (!deps.approval) return;
  const decision = deps.approval.evaluate(toolName, input);
  if (decision !== "approved") {
    deps.emit?.({ runId: deps.runId, traceId: deps.traceId, tool: toolName, status: "denied", timestamp: new Date().toISOString(), data: { decision } });
    throw new Error(`Cusimanse policy denied tool ${toolName}: ${decision}`);
  }
}

function lifecycle(deps: ResearchToolDependencies, tool: string, status: ResearchToolEvent["status"], data?: Record<string, unknown>, evidenceId?: string): void {
  deps.emit?.({ runId: deps.runId, traceId: deps.traceId, tool, status, timestamp: new Date().toISOString(), ...(data ? { data } : {}), ...(evidenceId ? { evidenceId } : {}) });
}

function journalObservation(deps: ResearchToolDependencies, tool: string, data: Record<string, unknown>): string | undefined {
  if (!deps.evidenceJournal) return undefined;
  const evidenceId = createEvidenceId(deps.runId, tool, deps.evidenceJournal.list().length);
  deps.evidenceJournal.append({ id: evidenceId, objectiveId: deps.objective.id, runId: deps.runId, traceId: deps.traceId, tool, kind: "observation", data, timestamp: new Date().toISOString() });

  if (deps.stateStore) {
    deps.stateStore.append({ type: "observation.recorded", observation: { tool, evidenceId, ...data } });
    deps.stateStore.append({ type: "evidence.recorded", evidenceId });
  } else if (deps.state) {
    deps.state = appendResearchObservation(deps.state, { tool, evidenceId, ...data }, new Date().toISOString(), deps.traceId);
    deps.state = appendResearchEvidence(deps.state, evidenceId, new Date().toISOString(), deps.traceId);
  }
  return evidenceId;
}

export function createGovernedResearchTools(deps: ResearchToolDependencies): ToolSet {
  return {
    create_lab: tool({ description: "Create the disposable research lab described by an approved sandbox specification.", inputSchema: z.object({ ...base, id: z.string().min(1), image: z.string().min(1), cpus: z.number().int().positive(), memoryMb: z.number().int().positive(), networkIsolation: z.enum(["airgap", "dns-only", "full"]), guestProbeBinary: z.string().optional() }), execute: async (input) => {
      lifecycle(deps, "create_lab", "started"); resolveAndGuard(deps, "create_lab", "lab.create", input);
      await deps.compute.createSandbox({ id: input.id, image: input.image, cpus: input.cpus, memoryMb: input.memoryMb, networkIsolation: input.networkIsolation, ...(input.guestProbeBinary ? { guestProbeBinary: input.guestProbeBinary } : {}) });
      const evidenceId = journalObservation(deps, "create_lab", { sandboxId: input.id, image: input.image, networkIsolation: input.networkIsolation }); lifecycle(deps, "create_lab", "completed", { sandboxId: input.id }, evidenceId); return { success: true, sandboxId: input.id, evidenceId };
    }),
    execute_workload: tool({ description: "Execute an approved workload through the Cusimanse compute provider; no arbitrary host shell is exposed.", inputSchema: z.object({ ...base, command: z.string().min(1), args: z.array(z.string()).default([]) }), execute: async (input) => {
      lifecycle(deps, "execute_workload", "started"); resolveAndGuard(deps, "execute_workload", "workload.execute", input); const result = await deps.compute.exec(input.command, input.args);
      const data = { exitCode: result.exitCode, stdout: result.stdout, stderr: result.stderr, durationMs: result.durationMs }; const evidenceId = journalObservation(deps, "execute_workload", data); lifecycle(deps, "execute_workload", "completed", { exitCode: result.exitCode, durationMs: result.durationMs }, evidenceId); return { success: result.exitCode === 0, ...data, evidenceId };
    }),
    observe_network: tool({ description: "Request network observation for the active research lab. A real observer must be attached by the runtime adapter.", inputSchema: z.object({ ...base, filter: z.string().optional(), durationSeconds: z.number().int().positive().max(3600).default(30) }), execute: async (input) => {
      resolveAndGuard(deps, "observe_network", "network.observe", input); const data = { observed: false, filter: input.filter ?? "", durationSeconds: input.durationSeconds, reason: "No network observer is attached to this runtime." }; const evidenceId = journalObservation(deps, "observe_network", data); lifecycle(deps, "observe_network", "completed", data, evidenceId); return { ...data, evidenceId };
    }),
    query_telemetry: tool({ description: "Query runtime telemetry through a governed adapter; never fabricates telemetry.", inputSchema: z.object({ ...base, query: z.string().min(1) }), execute: async (input) => {
      resolveAndGuard(deps, "query_telemetry", "telemetry.query", input); const data = { observed: false, query: input.query, reason: "No telemetry query adapter is attached to this runtime." }; const evidenceId = journalObservation(deps, "query_telemetry", data); lifecycle(deps, "query_telemetry", "completed", data, evidenceId); return { ...data, evidenceId };
    }),
    inspect_artifact: tool({ description: "Inspect a previously materialized artifact by copying it from the isolated lab.", inputSchema: z.object({ ...base, guestPath: z.string().min(1), hostPath: z.string().min(1) }), execute: async (input) => {
      resolveAndGuard(deps, "inspect_artifact", "artifact.inspect", input); await deps.compute.extractArtifacts(input.guestPath, input.hostPath); const data = { success: true, guestPath: input.guestPath, hostPath: input.hostPath }; const evidenceId = journalObservation(deps, "inspect_artifact", data); lifecycle(deps, "inspect_artifact", "completed", data, evidenceId); return { ...data, evidenceId };
    }),
    verify_finding: tool({ description: "Request finding verification without treating an unverified claim as evidence.", inputSchema: z.object({ ...base, findingId: z.string().min(1), evidenceRefs: z.array(z.string()).default([]) }), execute: async (input) => {
      resolveAndGuard(deps, "verify_finding", "finding.verify", input); const data = { verified: false, findingId: input.findingId, evidenceRefs: input.evidenceRefs, reason: "Verification requires a configured verifier adapter." }; const evidenceId = journalObservation(deps, "verify_finding", data); lifecycle(deps, "verify_finding", "completed", data, evidenceId); return { ...data, evidenceId };
    }),
    destroy_lab: tool({ description: "Destroy the active disposable research lab.", inputSchema: z.object({ ...base, reason: z.string().min(1) }), execute: async (input) => {
      lifecycle(deps, "destroy_lab", "started"); resolveAndGuard(deps, "destroy_lab", "lab.destroy", input); await deps.compute.destroy(); lifecycle(deps, "destroy_lab", "completed", { reason: input.reason }); return { success: true };
    }),
  };
}
