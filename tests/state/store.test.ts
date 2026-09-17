import { describe, expect, it } from "vitest";
import { createAutonomousResearchState } from "../../src/state/research.js";
import { createResearchStateStore } from "../../src/state/store.js";

describe("ResearchStateStore", () => {
  it("retains reducer state across appended events", () => {
    const store = createResearchStateStore(createAutonomousResearchState("obj-1"));
    const first = store.append({ type: "observation.recorded", observation: { evidenceId: "evidence:run-1:0:test", exitCode: 0 } });
    const second = store.append({ type: "evidence.recorded", evidenceId: "evidence:run-1:0:test" });

    expect(first.state.observations).toHaveLength(1);
    expect(second.state.evidenceIds).toEqual(["evidence:run-1:0:test"]);
    expect(store.get()).toEqual(second);
    expect(second.revision).toBe(2);
  });
});
