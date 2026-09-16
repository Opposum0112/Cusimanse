import assert from "node:assert/strict";
import test from "node:test";
import type { OperatorPort, ResearchSessionPort } from "../src/gateway/contracts.js";
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

function makeSessionOperator(): ResearchSessionPort {
  return {
    ...makeOperator(),
    async createResearchSession({ recipe }) {
      const experimentId = String((recipe as { experiment_id?: unknown }).experiment_id ?? "exp");
      return { experimentId, state: { experimentId, phase: "created", revision: 0, observations: [], evidence: [], operations: [], events: [] } };
    },
    async completeResearch(experimentId) {
      return { experimentId, state: { experimentId, phase: "completed", revision: 1, observations: [], evidence: [], operations: [], events: [] } };
    },
  };
}

test("MCP adapter is built over OperatorPort", () => {
  const server = createCusimanseMcpServer(makeOperator());
  assert.ok(server);
});

test("MCP adapter surface is proposal/state/evidence only for a plain OperatorPort", () => {
  const server = createCusimanseMcpServer(makeOperator());
  const tools = (server as unknown as { _registeredTools?: Record<string, unknown> })._registeredTools;
  assert.ok(tools);
  assert.deepEqual(Object.keys(tools).sort(), ["research_evidence", "research_propose", "research_state"]);
  assert.equal("execute_shell" in tools, false);
  assert.equal("shell" in tools, false);
});

test("MCP session operator exposes lifecycle plus governed research tools", () => {
  const server = createCusimanseMcpServer(makeSessionOperator());
  const tools = (server as unknown as { _registeredTools?: Record<string, unknown> })._registeredTools;
  assert.ok(tools);
  assert.deepEqual(Object.keys(tools).sort(), [
    "complete_research",
    "create_research_session",
    "research_evidence",
    "research_propose",
    "research_state",
  ]);
  assert.equal("execute_shell" in tools, false);
  assert.equal("shell" in tools, false);
});
