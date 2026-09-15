export type OperationStatus = "proposed" | "pending-approval" | "running" | "succeeded" | "failed" | "denied";

export interface Operation<TParameters = Record<string, unknown>> {
  id: string;
  experimentId: string;
  intentId: string;
  kind: string;
  capability: string;
  parameters: TParameters;
  requiresApproval: boolean;
}

export interface OperationResult {
  operationId: string;
  status: "succeeded" | "failed" | "denied";
  output?: unknown;
  error?: string;
  evidenceRefs: string[];
}

export class OperationError extends Error {
  constructor(message: string) { super(message); this.name = "OperationError"; }
}

const allowedTransitions: Record<OperationStatus, OperationStatus[]> = {
  proposed: ["pending-approval", "running", "denied"],
  "pending-approval": ["running", "denied"],
  running: ["succeeded", "failed"],
  succeeded: [], failed: [], denied: [],
};

export class OperationEngine {
  private readonly statuses = new Map<string, OperationStatus>();

  register(operation: Operation): void {
    if (this.statuses.has(operation.id)) throw new OperationError(`Operation already registered: ${operation.id}`);
    this.statuses.set(operation.id, "proposed");
  }

  authorize(operation: Operation, approved: boolean): OperationStatus {
    const current = this.statuses.get(operation.id);
    if (!current) throw new OperationError(`Unknown operation: ${operation.id}`);
    if (operation.requiresApproval && !approved) {
      this.transition(operation.id, "pending-approval");
      return "pending-approval";
    }
    this.transition(operation.id, "running");
    return "running";
  }

  approve(operationId: string): OperationStatus { this.transition(operationId, "running"); return "running"; }
  deny(operationId: string): OperationStatus { this.transition(operationId, "denied"); return "denied"; }
  succeed(operationId: string): OperationStatus { this.transition(operationId, "succeeded"); return "succeeded"; }
  fail(operationId: string): OperationStatus { this.transition(operationId, "failed"); return "failed"; }
  status(operationId: string): OperationStatus | undefined { return this.statuses.get(operationId); }

  private transition(id: string, next: OperationStatus): void {
    const current = this.statuses.get(id);
    if (!current) throw new OperationError(`Unknown operation: ${id}`);
    if (!allowedTransitions[current].includes(next)) throw new OperationError(`Invalid operation transition: ${current} -> ${next}`);
    this.statuses.set(id, next);
  }
}
