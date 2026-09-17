import { describe, expect, it } from "vitest";
import { EvidenceJournal, createEvidenceId, createCusimanseResearchState, appendResearchEvidence, appendResearchObservation } from "../../src/state/index.js";

describe("EvidenceJournal", () => {
  it("stores immutable evidence records with deterministic ids", () => {
    const journal = new EvidenceJournal();
    const id = createEvidenceId("run-1", "execute_workload", 0);
    journal.append({ id, objectiveId: "obj-1", runId: "run-1", traceId: "trace-1", tool: "execute_workload", kind: "observation", data: { exitCode: 0 }, timestamp: "2026-09-17T00:00:00.000Z" });
    expect(journal.get(id)?.id).toBe(id);
    expect(journal.list()).toHaveLength(1);
    expect(() => journal.append({ id, objectiveId: "obj-1", runId: "run-1", traceId: "trace-1", tool: "execute_workload", kind: "observation", data: {}, timestamp: "2026-09-17T00:00:01.000Z" })).toThrow(/already exists/);
  });
});

describe("research evidence events", () => {
  it("links evidence ids into autonomous research state", () => {
    let state = createCusimanseResearchState("exp-1", "obj-1");
    state = appendResearchObservation(state, { source: "execute_workload", exitCode: 0 });
    state = appendResearchEvidence(state, "evidence:run-1:0:execute_workload");
    expect(state.autonomous.observations).toHaveLength(1);
    expect(state.autonomous.evidenceIds).toEqual(["evidence:run-1:0:execute_workload"]);
    expect(state.events).toHaveLength(3);
    expect(state.events.map((event) => event.sequence)).toEqual([0, 1, 2]);
  });
});
