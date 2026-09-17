import type { ResearchEvent } from "./research.js";
import { appendAggregateResearchEvent, type CusimanseResearchState } from "./index.js";

export interface ResearchStateStore {
  get(): CusimanseResearchState;
  append(event: ResearchEvent, now?: string, causationId?: string): CusimanseResearchState;
}

export class InMemoryResearchStateStore implements ResearchStateStore {
  private state: CusimanseResearchState;

  constructor(initial: CusimanseResearchState) {
    this.state = initial;
  }

  get(): CusimanseResearchState {
    return this.state;
  }

  append(event: ResearchEvent, now = new Date().toISOString(), causationId?: string): CusimanseResearchState {
    this.state = appendAggregateResearchEvent(this.state, event, now, causationId);
    return this.state;
  }
}

export function createResearchStateStore(initial: CusimanseResearchState): ResearchStateStore {
  return new InMemoryResearchStateStore(initial);
}
