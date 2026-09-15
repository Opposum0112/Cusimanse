import type { ExperimentRecipe } from "../ir/index.js";

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

  if (issues.length) throw new RecipeValidationError("Recipe validation failed.", issues);

  return {
    version: "v1",
    experimentId: record.experiment_id as string,
    source,
    intents: (record.intents as Array<Record<string, unknown>>).map((intent) => ({
      id: intent.id as string,
      capability: intent.capability as string,
      parameters: isRecord(intent.parameters) ? intent.parameters : {},
      dependsOn: Array.isArray(intent.depends_on) ? intent.depends_on.filter((x): x is string => typeof x === "string") : [],
    })),
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
