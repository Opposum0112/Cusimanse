import { strict as assert } from "node:assert";
import { appendEvent, createResearchState, transitionPhase } from "../../src/state/index.js";

const state = createResearchState("exp-1", "2026-09-16T00:00:00.000Z");
assert.equal(state.phase, "created");
assert.equal(state.revision, 0);
assert.equal(state.events[0]?.type, "experiment.created");

const planning = transitionPhase(
  state,
  "planning",
  "intent.planned",
  { intentId: "prepare" },
  "2026-09-16T00:01:00.000Z",
);
assert.equal(planning.phase, "planning");
assert.equal(planning.revision, 1);
assert.equal(planning.events.length, 2);

const observed = appendEvent(planning, {
  id: "evt-observed",
  type: "observation.recorded",
  experimentId: "exp-1",
  timestamp: "2026-09-16T00:02:00.000Z",
  payload: { source: "test", data: { ok: true } },
});
assert.equal(observed.revision, 2);
assert.equal(observed.events.at(-1)?.type, "observation.recorded");

assert.throws(() => appendEvent(planning, {
  id: "evt-wrong-experiment",
  type: "operation.started",
  experimentId: "other",
  timestamp: "2026-09-16T00:03:00.000Z",
  payload: {},
}));
