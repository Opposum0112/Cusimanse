import type { ResearchEvent } from "./research.js";
import { applyResearchEvent } from "./research.js";
import type { AutonomousResearchState } from "./research.js";

export interface ResearchStateSnapshot {
  objectiveId: string;
  state: AutonomousResearchState;
  revision: number;
}

export interface ResearchStateStore {
  get(): ResearchStateSnapshot;
  append(event: ResearchEvent): ResearchStateSnapshot;
}

export class InMemoryResearchStateStore implements ResearchStateStore {
  private state: AutonomousResearchState;
  private revision = 0;

  constructor(initial: AutonomousResearchState) {
    this.state = initial;
  }

  get(): ResearchStateSnapshot {
    return { objectiveId: this.state.objectiveId, state: this.state, revision: this.revision };
  }

  append(event: ResearchEvent): ResearchStateSnapshot {
    this.state = applyResearchEvent(this.state, event);
    this.revision += 1;
    return this.get();
  }
}

export function createResearchStateStore(initial: AutonomousResearchState): ResearchStateStore {
  return new InMemoryResearchStateStore(initial);
}
