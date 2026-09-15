export type PolicyDecision = "allow" | "approval-required" | "deny";

export interface PolicyContext {
  experimentId: string;
  intentId: string;
  capability: string;
  operationKind: string;
  parameters: Record<string, unknown>;
}

export interface PolicyRule {
  id: string;
  capability: string;
  operationKind?: string;
  decision: PolicyDecision;
  reason: string;
}

export interface PolicyEvaluation {
  decision: PolicyDecision;
  ruleId: string;
  reason: string;
}

export interface ApprovalRequest {
  id: string;
  experimentId: string;
  intentId: string;
  capability: string;
  operationKind: string;
  status: "pending" | "granted" | "denied";
  requestedAt: string;
  decidedAt?: string;
  decidedBy?: string;
  reason?: string;
}

export class PolicyError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PolicyError";
  }
}

export class PolicyEngine {
  private readonly rules: PolicyRule[];

  constructor(rules: PolicyRule[]) {
    const ids = new Set<string>();
    for (const rule of rules) {
      if (ids.has(rule.id)) throw new PolicyError(`Duplicate policy rule: ${rule.id}`);
      ids.add(rule.id);
    }
    this.rules = [...rules].sort((a, b) => a.id.localeCompare(b.id));
  }

  evaluate(context: PolicyContext): PolicyEvaluation {
    const matches = this.rules.filter(
      (rule) =>
        rule.capability === context.capability &&
        (rule.operationKind === undefined || rule.operationKind === context.operationKind),
    );
    const rule = matches[0];
    if (!rule) {
      return { decision: "deny", ruleId: "default-deny", reason: "No policy rule matched." };
    }
    return { decision: rule.decision, ruleId: rule.id, reason: rule.reason };
  }
}

function approvalId(): string {
  return `apr_${crypto.randomUUID()}`;
}

export class ApprovalManager {
  private readonly requests = new Map<string, ApprovalRequest>();

  request(context: PolicyContext): ApprovalRequest {
    const request: ApprovalRequest = {
      id: approvalId(),
      experimentId: context.experimentId,
      intentId: context.intentId,
      capability: context.capability,
      operationKind: context.operationKind,
      status: "pending",
      requestedAt: new Date().toISOString(),
    };
    this.requests.set(request.id, request);
    return { ...request };
  }

  grant(id: string, decidedBy: string, reason?: string): ApprovalRequest {
    return this.decide(id, "granted", decidedBy, reason);
  }

  deny(id: string, decidedBy: string, reason?: string): ApprovalRequest {
    return this.decide(id, "denied", decidedBy, reason);
  }

  get(id: string): ApprovalRequest | undefined {
    const request = this.requests.get(id);
    return request ? { ...request } : undefined;
  }

  private decide(
    id: string,
    status: "granted" | "denied",
    decidedBy: string,
    reason?: string,
  ): ApprovalRequest {
    const request = this.requests.get(id);
    if (!request) throw new PolicyError(`Unknown approval request: ${id}`);
    if (request.status !== "pending") throw new PolicyError(`Approval is already decided: ${id}`);
    const decided: ApprovalRequest = {
      ...request,
      status,
      decidedAt: new Date().toISOString(),
      decidedBy,
      ...(reason === undefined ? {} : { reason }),
    };
    this.requests.set(id, decided);
    return { ...decided };
  }
}
