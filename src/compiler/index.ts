import { createHash } from "node:crypto";
import type {
  EvidenceKind,
  EvidenceRequirement,
  ExperimentRecipe,
  ResearchContract,
  ResearchQuestion,
  ResearchScope,
} from "../ir/index.js";

export interface RecipeCompiler {
  compile(input: unknown, source?: { format: "yaml" | "json"; path: string }): ExperimentRecipe;
}

export class RecipeValidationError extends Error {
  constructor(message: string, readonly issues: string[] = []) {
    super(message);
    this.name = "RecipeValidationError";
  }
}

const requiredStrings = ["api_version", "kind", "experiment_id"] as const;
const evidenceKinds = new Set<EvidenceKind>(["file", "network", "process", "log", "artifact", "other"]);

export function compileRecipe(
  input: unknown,
  source: { format: "yaml" | "json"; path: string } = { format: "yaml", path: "<memory>" },
): ExperimentRecipe {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new RecipeValidationError("Recipe root must be an object.");
  }

  const record = input as Record<string, unknown>;
  const issues = requiredStrings
    .filter((key) => typeof record[key] !== "string" || (record[key] as string).length === 0)
    .map((key) => `${key} is required and must be a non-empty string`);

  if (!Array.isArray(record.intents)) issues.push("intents must be an array");
  if (record.scope !== undefined && (typeof record.scope !== "object" || record.scope === null)) {
    issues.push("scope must be an object when provided");
  }

  if (Array.isArray(record.intents)) {
    record.intents.forEach((intent, index) => {
      if (!intent || typeof intent !== "object") {
        issues.push(`intents[${index}] must be an object`);
        return;
      }
      const item = intent as Record<string, unknown>;
      if (typeof item.id !== "string" || !item.id) issues.push(`intents[${index}].id is required`);
      if (typeof item.capability !== "string" || !item.capability) {
        issues.push(`intents[${index}].capability is required`);
      }
      if (item.depends_on !== undefined && !Array.isArray(item.depends_on)) {
        issues.push(`intents[${index}].depends_on must be an array`);
      }
    });
  }

  const allowedCapabilities = parseStringArray(record.allowed_capabilities, "allowed_capabilities", issues);
  if (allowedCapabilities && Array.isArray(record.intents)) {
    for (const intent of record.intents as Array<Record<string, unknown>>) {
      if (typeof intent.capability === "string" && !allowedCapabilities.includes(intent.capability)) {
        issues.push(`intent ${String(intent.id)} uses capability ${intent.capability} which is not on allowed_capabilities`);
      }
    }
  }

  const contract = compileContract(record, allowedCapabilities, issues);
  if (issues.length) throw new RecipeValidationError("Recipe validation failed.", issues);

  const intents = (record.intents as Array<Record<string, unknown>>).map((intent) => ({
    id: intent.id as string,
    capability: intent.capability as string,
    parameters: isRecord(intent.parameters) ? intent.parameters : {},
    dependsOn: Array.isArray(intent.depends_on) ? intent.depends_on.filter((x): x is string => typeof x === "string") : [],
  }));

  const recipe: ExperimentRecipe = {
    version: "v1",
    experimentId: record.experiment_id as string,
    source,
    intents,
    contract,
  };
  recipe.contract.hash = hashContract(recipe);
  return recipe;
}

function compileContract(
  record: Record<string, unknown>,
  allowedCapabilities: string[] | undefined,
  issues: string[],
): ResearchContract {
  const question = compileQuestion(record.research_question, issues);
  const scope = compileScope(record.scope, issues);
  const evidenceRequired = compileEvidenceRequired(record.evidence_required, issues);
  const stopWhen = compileStopWhen(record.stop_when, issues);
  const destroy = compileDestroy(record.destroy, issues);
  const operationKinds = parseStringArray(record.operation_kinds, "operation_kinds", issues) ?? [];

  const contract: ResearchContract = {
    contractVersion: typeof record.contract_version === "string" && record.contract_version ? record.contract_version : "0.2",
    operationKinds,
    evidenceRequired,
    stopWhen,
  };
  if (question) contract.question = question;
  if (scope) contract.scope = scope;
  if (allowedCapabilities) contract.allowedCapabilities = allowedCapabilities;
  if (destroy) contract.destroy = destroy;
  return contract;
}

function compileQuestion(value: unknown, issues: string[]): ResearchQuestion | undefined {
  if (value === undefined) return undefined;
  if (!isRecord(value)) {
    issues.push("research_question must be an object when provided");
    return undefined;
  }
  if (typeof value.id !== "string" || !value.id) issues.push("research_question.id is required");
  if (typeof value.question !== "string" || !value.question) issues.push("research_question.question is required");
  const nonGoals = Array.isArray(value.non_goals)
    ? value.non_goals.filter((item): item is string => typeof item === "string")
    : [];
  if (typeof value.id !== "string" || typeof value.question !== "string") return undefined;
  return { id: value.id, question: value.question, nonGoals };
}

function compileScope(value: unknown, issues: string[]): ResearchScope | undefined {
  if (value === undefined) return undefined;
  if (!isRecord(value)) {
    issues.push("scope must be an object when provided");
    return undefined;
  }
  const scope: ResearchScope = {
    networks: parseStringArray(value.networks, "scope.networks", issues) ?? [],
    paths: parseStringArray(value.paths, "scope.paths", issues) ?? [],
    hosts: parseStringArray(value.hosts, "scope.hosts", issues) ?? [],
  };
  if (isRecord(value.compute)) {
    const compute: NonNullable<ResearchScope["compute"]> = {};
    if (typeof value.compute.provider === "string") compute.provider = value.compute.provider;
    if (typeof value.compute.profile === "string") compute.profile = value.compute.profile;
    if (typeof value.compute.disposable === "boolean") compute.disposable = value.compute.disposable;
    if (Object.keys(compute).length) scope.compute = compute;
  }
  if (typeof value.egress === "string") scope.egressMode = value.egress;
  if (isRecord(value.egress) && typeof value.egress.mode === "string") scope.egressMode = value.egress.mode;
  return scope;
}

function compileEvidenceRequired(value: unknown, issues: string[]): EvidenceRequirement[] {
  if (value === undefined) return [];
  if (!Array.isArray(value)) {
    issues.push("evidence_required must be an array when provided");
    return [];
  }
  const requirements: EvidenceRequirement[] = [];
  value.forEach((item, index) => {
    if (!isRecord(item) || typeof item.type !== "string") {
      issues.push(`evidence_required[${index}].type is required`);
      return;
    }
    if (!evidenceKinds.has(item.type as EvidenceKind)) {
      issues.push(`evidence_required[${index}].type is not a known evidence kind`);
      return;
    }
    const requirement: EvidenceRequirement = { type: item.type as EvidenceKind };
    if (typeof item.produced_by === "string") requirement.producedBy = item.produced_by;
    requirements.push(requirement);
  });
  return requirements;
}

function compileStopWhen(value: unknown, issues: string[]): ResearchContract["stopWhen"] {
  if (value === undefined) return { allEvidenceRequired: false };
  if (!isRecord(value)) {
    issues.push("stop_when must be an object when provided");
    return { allEvidenceRequired: false };
  }
  const stopWhen: ResearchContract["stopWhen"] = {
    allEvidenceRequired: value.all_evidence_required === true || (Array.isArray(value) === false && value.all_evidence_required === true),
  };
  if (Array.isArray(value)) {
    stopWhen.allEvidenceRequired = value.includes("all_evidence_required");
    for (const item of value) {
      if (isRecord(item) && typeof item.max_proposals === "number") stopWhen.maxProposals = item.max_proposals;
      if (isRecord(item) && typeof item.max_lifetime_minutes === "number") stopWhen.maxLifetimeMinutes = item.max_lifetime_minutes;
    }
  }
  if (typeof value.max_proposals === "number") stopWhen.maxProposals = value.max_proposals;
  if (typeof value.max_lifetime_minutes === "number") stopWhen.maxLifetimeMinutes = value.max_lifetime_minutes;
  if (value.all_evidence_required === true) stopWhen.allEvidenceRequired = true;
  return stopWhen;
}

function compileDestroy(value: unknown, issues: string[]): ResearchContract["destroy"] | undefined {
  if (value === undefined) return undefined;
  if (!isRecord(value)) {
    issues.push("destroy must be an object when provided");
    return undefined;
  }
  const capability = typeof value.capability === "string" ? value.capability : "vm.destroy";
  return {
    capability,
    requireEvidenceSealed: value.require_evidence_sealed !== false,
  };
}

function parseStringArray(value: unknown, label: string, issues: string[]): string[] | undefined {
  if (value === undefined) return undefined;
  if (!Array.isArray(value) || value.some((item) => typeof item !== "string")) {
    issues.push(`${label} must be an array of strings when provided`);
    return undefined;
  }
  return value as string[];
}

function hashContract(recipe: ExperimentRecipe): string {
  const canonical = {
    experimentId: recipe.experimentId,
    intents: recipe.intents,
    contract: { ...recipe.contract, hash: undefined },
  };
  return createHash("sha256").update(JSON.stringify(canonical)).digest("hex");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
