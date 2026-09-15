import test from "node:test";
import assert from "node:assert/strict";
import { reasoningProposalSchema } from "../../src/llm/index.js";

test("reasoning schema accepts declarative proposal", () => {
  assert.equal(reasoningProposalSchema.safeParse({ intent: "collect logs", capability: "evidence.collect", complete: false }).success, true);
});

test("reasoning schema rejects arbitrary execution fields", () => {
  assert.equal(reasoningProposalSchema.safeParse({ intent: "run command", command: "rm -rf /", complete: false }).success, false);
});
