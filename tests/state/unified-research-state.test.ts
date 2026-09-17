import assert from "node:assert/strict";
import test from "node:test";
import { applyAutonomousResearchEvent, createCusimanseResearchState } from "../../src/state/index.js";

test("unified state keeps runtime and autonomous research state together", () => {
  let state = createCusimanseResearchState("experiment-1", "objective-1", 3, "2026-01-01T00:00:00.000Z");
  assert.equal(state.experiment.experimentId, "experiment-1");
  assert.equal(state.autonomous.objectiveId, "objective-1");
  assert.equal(state.autonomous.phase, "planning");
  assert.equal(state.events.length, 1);
  assert.equal(state.events[0]?.sequence, 0);

  state = applyAutonomousResearchEvent(state, { type: "phase.changed", phase: "hypothesizing" });
  state = applyAutonomousResearchEvent(state, {
    type: "hypothesis.proposed",
    hypothesis: { id: "h-1", statement: "test hypothesis", status: "open", evidenceIds: [] },
  });

  assert.equal(state.autonomous.phase, "hypothesizing");
  assert.equal(state.autonomous.hypotheses[0]?.id, "h-1");
  assert.equal(state.experiment.revision, 0);
  assert.equal(state.revision, 2);
  assert.deepEqual(state.events.map((event) => event.sequence), [0, 1, 2]);
  assert.deepEqual(state.events.map((event) => event.type), ["research", "research", "research"]);
});

test("unified aggregate preserves causation and rejects invalid transitions atomically", () => {
  let state = createCusimanseResearchState("experiment-2");
  const before = state.events.length;

  assert.throws(() => applyAutonomousResearchEvent(state, { type: "phase.changed", phase: "verifying" }), /Invalid research phase transition/);
  assert.equal(state.events.length, before);

  state = applyAutonomousResearchEvent(state, { type: "phase.changed", phase: "hypothesizing" });
  assert.equal(state.events[1]?.causationId, undefined);
});
