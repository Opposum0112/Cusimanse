export interface CapabilityIntent {
  id: string;
  capability: string;
  parameters: Record<string, unknown>;
  dependsOn: string[];
}

export interface CusimanseIR {
  version: "v1";
  experimentId: string;
  source: { format: "yaml" | "json"; path: string };
  intents: CapabilityIntent[];
}

export interface ExperimentRecipe {
  version: "v1";
  experimentId: string;
  source: { format: "yaml" | "json"; path: string };
  intents: CapabilityIntent[];
}

export interface DependencyGraph {
  nodes: string[];
  dependencies: Record<string, string[]>;
}
