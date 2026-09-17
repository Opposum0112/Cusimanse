import { describe, expect, it } from "vitest";
import { createCusimanseResearchState } from "../../src/state/index.js";
import { createResearchStateStore } from "../../src/state/store.js";

describe("ResearchStateStore", () => {
  it("retains reducer state across appended events", () => {
    const store = createResearchStateStore(createCusimanseResearchState("exp-1", "obj-1"));
    const first = store.append({ type: "observation.recorded", observation: { evidenceId: "evidence:run-1:0:test", exitCode: 0 } }, "2026-09-17T00:00:00.000Z", "trace-1");
    const second = store.append({ type: "evidence.recorded", evidenceId: "evidence:run-1:0:test" }, "2026-09-17T00:00:01.000Z", "trace-1");

    expect(first.autonomous.observations).toHaveLength(1);
    expect(second.autonomous.evidenceIds).toEqual(["evidence:run-1:0:test"]);
    expect(store.get()).toBe(second);
    expect(second.revision).toBe(2);
    expect(second.events).toHaveLength(3);
  });
});
