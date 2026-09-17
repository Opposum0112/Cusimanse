import assert from "node:assert/strict";
import test from "node:test";
import {
  addFinding,
  addHypothesis,
  createAutonomousResearchState,
  recordEvidence,
  recordObservation,
  shouldTerminate,
  updateHypothesisStatus,
  verifyFinding,
} from "../../src/agent/research-state.js";

test("research state supports hypothesis and finding lifecycle", () => {
  let state = createAutonomousResearchState("objective-1", 4);
  state = recordEvidence(state, "ev-1");
  state = addHypothesis(state, {
    id: "hyp-1",
    statement: "The workload creates an unexpected network connection",
    status: "open",
    evidenceIds: ["ev-1"],
  });
  state = updateHypothesisStatus(state, "hyp-1", "supported", ["ev-1"]);
  state = addFinding(state, {
    id: "finding-1",
    statement: "The observed connection is reproducible",
    hypothesisId: "hyp-1",
    evidenceIds: ["ev-1"],
    verification: "unverified",
  });

  assert.equal(state.hypotheses[0]?.status, "supported");
  assert.deepEqual(state.hypotheses[0]?.evidenceIds, ["ev-1"]);
  assert.equal(shouldTerminate(state), false);

  state = verifyFinding(state, "finding-1", ["ev-1"]);
  assert.equal(state.findings[0]?.verification, "verified");
  assert.equal(shouldTerminate(state), true);
});

test("research state rejects unknown references and duplicate IDs", () => {
  let state = createAutonomousResearchState("objective-2", 2);
  assert.throws(() => addHypothesis(state, {
    id: "hyp-1",
    statement: "x",
    status: "open",
    evidenceIds: ["missing"],
  }), /Unknown evidence/);

  state = recordEvidence(state, "ev-1");
  state = addHypothesis(state, { id: "hyp-1", statement: "x", status: "open", evidenceIds: [] });
  assert.throws(() => addHypothesis(state, { id: "hyp-1", statement: "y", status: "open", evidenceIds: [] }), /already exists/);
  assert.throws(() => addFinding(state, {
    id: "finding-1",
    statement: "y",
    hypothesisId: "missing-hypothesis",
    evidenceIds: [],
    verification: "unverified",
  }), /Unknown hypothesis/);
});

test("observation iteration is bounded by maxIterations", () => {
  let state = createAutonomousResearchState("objective-3", 1);
  state = recordObservation(state, { step: 1 });
  state = recordObservation(state, { step: 2 });
  assert.equal(state.iteration, 1);
  assert.equal(state.observations.length, 1);
  assert.equal(shouldTerminate(state), true);
});
