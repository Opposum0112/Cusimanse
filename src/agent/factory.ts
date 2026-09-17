import { modelFromConfig } from "../llm/provider.js";
import { AutonomousThreatResearchAgent } from "./research-loop.js";
import type { AgentDependencies, SecurityResearchAgent } from "./types.js";
import type { ResolvedConfig } from "../config/index.js";

export function getSecurityResearchAgent(config: ResolvedConfig, dependencies: Omit<AgentDependencies, "model">): SecurityResearchAgent {
  return new AutonomousThreatResearchAgent({ ...dependencies, model: modelFromConfig(config) });
}
