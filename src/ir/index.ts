export type EvidenceKind = "file" | "network" | "process" | "log" | "artifact" | "other";

export interface CapabilityIntent {
  id: string;
  capability: string;
  parameters: Record<string, unknown>;
  dependsOn: string[];
}

export interface ResearchQuestion {
  id: string;
  question: string;
  nonGoals: string[];
}

export interface ResearchScope {
  networks: string[];
  paths: string[];
  hosts: string[];
  compute?: {
    provider?: string;
    profile?: string;
    disposable?: boolean;
  };
  egressMode?: string;
}

export interface EvidenceRequirement {
  type: EvidenceKind;
  producedBy?: string;
}

export interface StopConditions {
  allEvidenceRequired: boolean;
  maxProposals?: number;
  maxLifetimeMinutes?: number;
}

export interface DestroyPolicy {
  capability: string;
  requireEvidenceSealed: boolean;
}

export interface ResearchContract {
  contractVersion: string;
  question?: ResearchQuestion;
  scope?: ResearchScope;
  allowedCapabilities?: string[];
  operationKinds: string[];
  evidenceRequired: EvidenceRequirement[];
  stopWhen: StopConditions;
  destroy?: DestroyPolicy;
  hash?: string;
}

export interface CusimanseIR {
  version: "v1";
  experimentId: string;
  source: { format: "yaml" | "json"; path: string };
  intents: CapabilityIntent[];
  contract: ResearchContract;
}

export type ExperimentRecipe = CusimanseIR;

export interface DependencyGraph {
  nodes: string[];
  dependencies: Record<string, string[]>;
}
