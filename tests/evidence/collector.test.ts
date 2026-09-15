import test from "node:test";
import assert from "node:assert/strict";
import { EvidenceCollector } from "../../src/evidence/index.js";

test("records SHA-256 and provenance", () => {
  const collector = new EvidenceCollector("exp-1");
  const record = collector.record({ kind: "log", uri: "artifact://install.log", content: "npm install\n" }, "op-1", "2026-01-01T00:00:00.000Z");
  assert.equal(record.sha256, "91798cd2a80925bcb68b48422574c907a730b6c5ef5b6583fb4fa2cacfd14f4c");
  assert.equal(record.provenance.experimentId, "exp-1");
  assert.equal(record.provenance.operationId, "op-1");
});
