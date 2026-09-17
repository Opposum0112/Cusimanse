import { describe, expect, it } from "vitest";
import { createEvidenceId, EvidenceJournal } from "../../src/state/evidence.js";
import { appendAggregateResearchEvent, createCusimanseResearchState } from "../../src/state/index.js";

describe("EvidenceJournal", () => {
  it("creates stable evidence ids and rejects duplicates", () => {
    expect(createEvidenceId("run-1", "execute_workload", 0)).toBe("evidence:run-1:0:execute_workload");
    const journal = new EvidenceJournal();
    const record = { id: "evidence:run-1:0:execute_workload", objectiveId: "obj-1", runId: "run-1", traceId: "trace-1", tool: "execute_workload", kind: "observation" as const, data: { exitCode: 0 }, timestamp: "2026-09-17T00:00:00.000Z" };
    expect(journal.append(record)).toEqual(record);
    expect(() => journal.append(record)).toThrow(/already exists/);
  });

  it("applies research observations through the aggregate reducer", () => {
    const initial = createCusimanseResearchState("exp-1", "obj-1");
    const next = appendAggregateResearchEvent(initial, {
      type: "observation.recorded",
      observation: { evidenceId: "evidence:run-1:0:execute_workload", exitCode: 0 },
    });
    expect(next.autonomous.observations).toHaveLength(1);
    expect(next.autonomous.observations[0]).toEqual({ evidenceId: "evidence:run-1:0:execute_workload", exitCode: 0 });
    expect(next.revision).toBe(1);
    expect(next.events).toHaveLength(2);
  });
});
