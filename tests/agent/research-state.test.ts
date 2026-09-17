import assert from "node:assert/strict";
import test from "node:test";
import {
  addFinding,
  addHypothesis,
  applyResearchEvent,
  createAutonomousResearchState,
  recordEvidence,
  recordObservation,
  shouldTerminate,
  transitionPhase,
  updateHypothesisStatus,
  verifyFinding,
} from "../../src/state/research.js";

test("research state supports hypothesis and finding lifecycle", () => {
  let state = createAutonomousResearchState("objective-1", 4);
  state = transitionPhase(state, "hypothesizing");
  state = recordEvidence(state, "ev-1");
  state = addHypothesis(state, { id: "hyp-1", statement: "The workload creates an unexpected network connection", status: "open", evidenceIds: ["ev-1"] });
  state = transitionPhase(state, "executing");
  state = transitionPhase(state, "observing");
  state = transitionPhase(state, "analyzing");
  state = updateHypothesisStatus(state, "hyp-1", "supported", ["ev-1"]);
  state = addFinding(state, { id: "finding-1", statement: "The observed connection is reproducible", hypothesisId: "hyp-1", evidenceIds: ["ev-1"], verification: "unverified" });
  state = transitionPhase(state, "verifying");
  state = verifyFinding(state, "finding-1", ["ev-1"]);
  state = transitionPhase(state, "completed");
  assert.equal(state.phase, "completed");
  assert.equal(state.findings[0]?.verification, "verified");
  assert.equal(shouldTerminate(state), true);
});

test("research state rejects invalid phase transitions and unknown references", () => {
  let state = createAutonomousResearchState("objective-2", 2);
  assert.throws(() => transitionPhase(state, "verifying"), /Invalid research phase transition/);
  assert.throws(() => addHypothesis(state, { id: "hyp-1", statement: "x", status: "open", evidenceIds: ["missing"] }), /Unknown evidence/);
  state = transitionPhase(state, "hypothesizing");
  state = recordEvidence(state, "ev-1");
  state = addHypothesis(state, { id: "hyp-1", statement: "x", status: "open", evidenceIds: [] });
  assert.throws(() => addHypothesis(state, { id: "hyp-1", statement: "y", status: "open", evidenceIds: [] }), /already exists/);
  assert.throws(() => addFinding(state, { id: "finding-1", statement: "y", hypothesisId: "missing-hypothesis", evidenceIds: [], verification: "unverified" }), /Unknown hypothesis/);
});

test("research events are applied through the canonical reducer", () => {
  let state = createAutonomousResearchState("objective-3", 3);
  state = applyResearchEvent(state, { type: "phase.changed", phase: "hypothesizing" });
  state = applyResearchEvent(state, { type: "evidence.recorded", evidenceId: "ev-1" });
  state = applyResearchEvent(state, { type: "hypothesis.proposed", hypothesis: { id: "hyp-1", statement: "test", status: "open", evidenceIds: ["ev-1"] } });
  assert.equal(state.hypotheses.length, 1);
  assert.equal(state.evidenceIds[0], "ev-1");
});

test("observation iteration is bounded by maxIterations", () => {
  let state = createAutonomousResearchState("objective-4", 1);
  state = recordObservation(state, { step: 1 });
  state = recordObservation(state, { step: 2 });
  assert.equal(state.iteration, 1);
  assert.equal(state.observations.length, 1);
  assert.equal(shouldTerminate(state), true);
});
