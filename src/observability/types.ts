export type ResearchEventKind = "agent" | "model" | "tool" | "policy" | "runtime" | "compute" | "evidence";

export interface ResearchEvent {
  runId: string;
  traceId: string;
  experimentId?: string;
  kind: ResearchEventKind;
  name: string;
  timestamp: string;
  durationMs?: number;
  data?: unknown;
}

export interface ResearchTracer {
  emit(event: ResearchEvent): void;
  snapshot(): ResearchEvent[];
}

export class InMemoryResearchTracer implements ResearchTracer {
  private readonly events: ResearchEvent[] = [];

  emit(event: ResearchEvent): void {
    this.events.push({ ...event });
  }

  snapshot(): ResearchEvent[] {
    return this.events.map((event) => ({ ...event }));
  }
}
