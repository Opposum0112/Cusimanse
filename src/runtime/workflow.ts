import type { CusimanseIR } from "../ir/index.js";
import { EvidenceCollector } from "../evidence/index.js";
import { LimaLifecycle, type LimaProfile } from "../adapters/lima.js";
import { RuntimeOrchestrator, type RuntimeDependencies, type RuntimeCycleResult } from "./index.js";
import { createResearchState, type ResearchState } from "../state/index.js";

export interface DisposableWorkflowOptions {
  limaProfile: LimaProfile;
  evidence: EvidenceCollector;
}

export class DisposableResearchWorkflow {
  private readonly runtime: RuntimeOrchestrator;

  constructor(
    private readonly lima: LimaLifecycle,
    dependencies: RuntimeDependencies,
  ) {
    this.runtime = new RuntimeOrchestrator(dependencies);
  }

  async run(ir: CusimanseIR, options: DisposableWorkflowOptions, initialState?: ResearchState): Promise<RuntimeCycleResult> {
    const state = initialState ?? createResearchState(ir.experimentId);
    await this.lima.create(options.limaProfile);
    try {
      return await this.runtime.run(ir, state);
    } finally {
      await this.lima.destroy(options.limaProfile.name);
    }
  }
}

export { EvidenceCollector };
