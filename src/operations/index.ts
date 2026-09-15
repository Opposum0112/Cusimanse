export type OperationKind = "tool" | "api" | "vm" | "shell" | "file" | "network" | "evidence";

export interface Operation<T = unknown> {
  id: string;
  kind: OperationKind;
  capability: string;
  parameters: T;
  requiresApproval: boolean;
}

export interface OperationResult {
  operationId: string;
  status: "succeeded" | "failed" | "denied";
  output?: unknown;
  error?: string;
  evidenceRefs: string[];
}
