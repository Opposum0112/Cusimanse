import { planExecution } from "../planner/index.js";
import type { CusimanseIR, CapabilityIntent } from "../ir/index.js";
import { CapabilityRegistry } from "../capabilities/index.js";
import { PolicyEngine, ApprovalManager, type PolicyContext } from "../policy/index.js";
import { OperationEngine, type Operation } from "../operations/index.js";
import { AdapterRegistry } from "../adapters/index.js";
import { appendEvent, transitionPhase, type ResearchState } from "../state/index.js";
import type { Reasoner, ReasoningProposal } from "../llm/index.js";
import { evaluateContractIntent } from "../contract/index.js";

export interface RuntimeDependencies { capabilities: CapabilityRegistry; policy: PolicyEngine; approvals: ApprovalManager; operations: OperationEngine; adapters: AdapterRegistry; reasoner?: Reasoner; }
export interface RuntimeCycleResult { state: ResearchState; proposals: ReasoningProposal[]; executedOperationIds: string[]; pendingApprovalIds: string[]; }

export class RuntimeOrchestrator {
  constructor(private readonly deps: RuntimeDependencies) {}
  async run(ir: CusimanseIR, initialState: ResearchState): Promise<RuntimeCycleResult> {
    let state = transitionPhase(initialState, "planning", "intent.planned", { count: ir.intents.length, contractHash: ir.contract.hash });
    const plan = planExecution(ir);
    const completed = new Set<string>(); const proposals: ReasoningProposal[] = [];
    const executedOperationIds: string[] = []; const pendingApprovalIds: string[] = [];
    for (const intentId of plan.orderedIntentIds) {
      const intent = ir.intents.find((candidate) => candidate.id === intentId) as CapabilityIntent;
      const contractDecision = evaluateContractIntent(ir, intent, state);
      if (!contractDecision.allowed) {
        const denied: Operation = { id: `op_${crypto.randomUUID()}`, experimentId: ir.experimentId, intentId: intent.id, kind: "contract", capability: intent.capability, parameters: intent.parameters, requiresApproval: false };
        this.deps.operations.register(denied); this.deps.operations.deny(denied.id);
        state = appendEvent(state, { id: `evt-${crypto.randomUUID()}`, type: "operation.proposed", experimentId: ir.experimentId, timestamp: new Date().toISOString(), payload: { operation: denied, contract: contractDecision } });
        continue;
      }
      const resolved = this.deps.capabilities.resolve(intent.capability, intent.parameters);
      const operationKind = resolved.descriptor.operationKinds[0];
      if (!operationKind) throw new Error(`Capability has no operation kind: ${intent.capability}`);
      const context: PolicyContext = { experimentId: ir.experimentId, intentId: intent.id, capability: intent.capability, operationKind, parameters: intent.parameters };
      const evaluation = this.deps.policy.evaluate(context);
      const operation: Operation = { id: `op_${crypto.randomUUID()}`, experimentId: ir.experimentId, intentId: intent.id, kind: operationKind, capability: intent.capability, parameters: resolved.parameters, requiresApproval: evaluation.decision === "approval-required" };
      this.deps.operations.register(operation);
      state = appendEvent(state, { id: `evt-${crypto.randomUUID()}`, type: "operation.proposed", experimentId: ir.experimentId, timestamp: new Date().toISOString(), payload: { operation, policy: evaluation, contract: contractDecision } });
      if (evaluation.decision === "deny") { this.deps.operations.deny(operation.id); continue; }
      if (evaluation.decision === "approval-required") { const approval = this.deps.approvals.request(context); this.deps.operations.authorize(operation, false); pendingApprovalIds.push(approval.id); state = appendEvent(state, { id: `evt-${crypto.randomUUID()}`, type: "approval.requested", experimentId: ir.experimentId, timestamp: new Date().toISOString(), payload: { approval, operationId: operation.id } }); continue; }
      this.deps.operations.authorize(operation, true);
      state = transitionPhase(state, "executing", "operation.started", { operationId: operation.id });
      const result = await this.deps.adapters.resolve(operation.capability).execute({ experimentId: operation.experimentId, operationId: operation.id }, operation.parameters);
      if (result.status === "succeeded") {
        this.deps.operations.succeed(operation.id); executedOperationIds.push(operation.id); completed.add(intent.id);
        const newEvidence = (result.evidenceRefs ?? []).map((uri) => ({ id: `ev_${crypto.randomUUID()}`, kind: "artifact" as const, uri, metadata: { source: operation.capability } }));
        if (newEvidence.length) state = { ...state, evidence: [...state.evidence, ...newEvidence] };
        state = appendEvent(state, { id: `evt-${crypto.randomUUID()}`, type: "operation.succeeded", experimentId: ir.experimentId, timestamp: new Date().toISOString(), payload: { operationId: operation.id, evidenceRefs: result.evidenceRefs } });
      } else { this.deps.operations.fail(operation.id); state = appendEvent(state, { id: `evt-${crypto.randomUUID()}`, type: "operation.failed", experimentId: ir.experimentId, timestamp: new Date().toISOString(), payload: { operationId: operation.id, error: result.error } }); }
    }
    state = transitionPhase(state, "observing", "observation.recorded", { source: "runtime", data: { executedOperationIds, pendingApprovalIds } });
    if (this.deps.reasoner) proposals.push(await this.deps.reasoner.reason(state));
    state = transitionPhase(state, pendingApprovalIds.length ? "awaiting-approval" : "completed", pendingApprovalIds.length ? "approval.requested" : "experiment.completed", { executedOperationIds, pendingApprovalIds, completedIntentIds: [...completed] });
    return { state, proposals, executedOperationIds, pendingApprovalIds };
  }
}

export { LocalExecutionRuntime } from "./local.js";
export { TemporalExecutionRuntime } from "./temporal.js";
export type { TemporalWorkflowDriver } from "./temporal.js";
export { GraphExecutionRuntime } from "./graph.js";
export type { GraphWorkflowDriver } from "./graph.js";
export { ExecutionRuntimeRegistry } from "./types.js";
export type { ExecutionRuntime, RuntimeContext } from "./types.js";
export { DisposableResearchWorkflow } from "./workflow.js";
export { TemporalDurableRuntime } from "./temporal-driver.js";
export type { TemporalRuntimeOptions } from "./temporal-driver.js";
