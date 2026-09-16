import type { CusimanseIR } from "../ir/index.js";
import type { ResearchState } from "../state/index.js";
import type { ExecutionResult, ExperimentRuntime } from "../runtime/spi/types.js";
export interface CARGatewayOptions { host?: string; port?: number; }
export interface ExperimentRunRequest { recipe: unknown; provider?: string; runtime?: string; }
export interface ExperimentRunResponse { runId: string; experimentId: string; result: ExecutionResult; }
export interface OperatorPort { runExperiment(request: ExperimentRunRequest): Promise<ExperimentRunResponse>; inspectEvidence(runId: string): Promise<{ runId: string; evidence: ResearchState["evidence"]; telemetry?: ExecutionResult["telemetry"] }>; promoteSkill(candidatePath: string): Promise<{ id: string; path: string }>; listProviders(): Promise<Array<{ id: string; available: boolean }>>; }
export interface ResearchSession { ir: CusimanseIR; state: ResearchState; runtime?: ExperimentRuntime; }
