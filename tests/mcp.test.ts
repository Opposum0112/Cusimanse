import assert from "node:assert/strict";
import test from "node:test";
import type { OperatorPort } from "../src/gateway/contracts.js";
import { createCusimanseMcpServer } from "../src/mcp/index.js";

function makeOperator(): OperatorPort {
  return {
    async getState(experimentId) {
      return { experimentId, state: { experimentId, phase: "ready", evidence: [], events: [] } as never };
    },
    async getEvidence(experimentId) {
      return { experimentId, evidence: [] };
    },
    async submitProposal(request) {
      return { experimentId: request.experimentId, accepted: false, proposal: request.proposal };
    },
  };
}

test("MCP adapter is built over OperatorPort", () => {
  const server = createCusimanseMcpServer(makeOperator());
  assert.ok(server);
});

test("MCP adapter surface is proposal/state/evidence only", () => {
  const server = createCusimanseMcpServer(makeOperator());
  const tools = (server as unknown as { _registeredTools?: Record<string, unknown> })._registeredTools;
  assert.ok(tools);
  assert.deepEqual(Object.keys(tools).sort(), ["research_evidence", "research_propose", "research_state"]);
  assert.equal("execute_shell" in tools, false);
  assert.equal("shell" in tools, false);
});
