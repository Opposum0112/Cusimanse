import type { ToolSet } from "ai";
import type { PolicyContext } from "./index.js";
import { PolicyEngine } from "./index.js";

export type ToolApprovalDecision = "approved" | "user-approval" | "denied";

export interface ApprovalAudit {
  toolName: string;
  input: unknown;
  decision: ToolApprovalDecision;
  reason: string;
  timestamp: string;
}
export type ApprovalSink = (audit: ApprovalAudit) => void;

export class FailClosedToolApproval {
  constructor(private readonly policy: PolicyEngine, private readonly sink: ApprovalSink = () => undefined) {}

  evaluate(toolName: string, input: unknown): ToolApprovalDecision {
    const record = isRecord(input) ? input : {};
    const capability = typeof record.capability === "string" ? record.capability : toolName;
    const operationKind = typeof record.operationKind === "string" ? record.operationKind : "tool";
    const parameters = isRecord(record.parameters) ? record.parameters : record;
    const context: PolicyContext = {
      experimentId: typeof record.experimentId === "string" ? record.experimentId : "unknown",
      intentId: typeof record.intentId === "string" ? record.intentId : "unknown",
      capability,
      operationKind,
      parameters,
    };

    let decision: ToolApprovalDecision = "denied";
    let reason = "No matching policy rule; fail closed.";
    try {
      const evaluation = this.policy.evaluate(context);
      reason = evaluation.reason;
      decision = evaluation.decision === "allow"
        ? "approved"
        : evaluation.decision === "approval-required"
          ? "user-approval"
          : "denied";
    } catch (error) {
      reason = error instanceof Error ? error.message : "Policy evaluation failed.";
    }

    this.sink({ toolName, input, decision, reason, timestamp: new Date().toISOString() });
    return decision;
  }

  configuration<TOOLS extends ToolSet>(): (context: { toolCall: { toolName: string; input: unknown } }) => ToolApprovalDecision {
    return ({ toolCall }) => this.evaluate(toolCall.toolName, toolCall.input);
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
