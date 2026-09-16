import type { CapabilityIntent, CusimanseIR, EvidenceKind } from "../ir/index.js";
import type { ResearchState } from "../state/index.js";

export type ContractDenyCode =
  | "not_in_contract_allowlist"
  | "destroy_blocked_until_evidence"
  | "max_proposals_exceeded"
  | "scope_violation";

export interface ContractDecision {
  allowed: boolean;
  code?: ContractDenyCode;
  reason: string;
}

export function listEvidenceKinds(state: ResearchState): Set<EvidenceKind> {
  return new Set(state.evidence.map((item) => item.kind));
}

export function isEvidenceSealed(ir: CusimanseIR, state: ResearchState): boolean {
  const required = ir.contract.evidenceRequired;
  if (!required.length) return true;
  const present = listEvidenceKinds(state);
  return required.every((requirement) => present.has(requirement.type));
}

export function countProposedOperations(state: ResearchState): number {
  return state.events.filter((event) => event.type === "operation.proposed").length;
}

export function evaluateContractIntent(
  ir: CusimanseIR,
  intent: CapabilityIntent,
  state: ResearchState,
): ContractDecision {
  const allowlist = ir.contract.allowedCapabilities;
  if (allowlist && !allowlist.includes(intent.capability)) {
    return {
      allowed: false,
      code: "not_in_contract_allowlist",
      reason: `Capability ${intent.capability} is not on the frozen contract allowlist.`,
    };
  }

  const maxProposals = ir.contract.stopWhen.maxProposals;
  if (typeof maxProposals === "number" && countProposedOperations(state) >= maxProposals) {
    return {
      allowed: false,
      code: "max_proposals_exceeded",
      reason: `Contract stop condition reached: max_proposals=${maxProposals}.`,
    };
  }

  const destroy = ir.contract.destroy;
  if (
    destroy &&
    intent.capability === destroy.capability &&
    destroy.requireEvidenceSealed &&
    !isEvidenceSealed(ir, state)
  ) {
    return {
      allowed: false,
      code: "destroy_blocked_until_evidence",
      reason: "vm.destroy is blocked until required evidence kinds are present.",
    };
  }

  const scope = ir.contract.scope;
  const workingDirectory = intent.parameters.working_directory;
  if (typeof workingDirectory === "string" && scope && scope.paths.length > 0) {
    const allowed = scope.paths.some(
      (path) => workingDirectory === path || workingDirectory.startsWith(`${path}/`),
    );
    if (!allowed) {
      return {
        allowed: false,
        code: "scope_violation",
        reason: `Parameter working_directory ${workingDirectory} is outside contract scope paths.`,
      };
    }
  }

  return { allowed: true, reason: "Contract permits this intent." };
}
