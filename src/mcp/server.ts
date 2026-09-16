import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import type { OperatorPort, ResearchSessionPort } from "../gateway/contracts.js";
import { reasoningProposalSchema } from "../llm/index.js";

/**
 * Build the MCP adapter over the harness-neutral OperatorPort.
 *
 * MCP is only the interoperability boundary. It never exposes arbitrary
 * shell/process execution; executable requests cross OperatorPort, where
 * Cusimanse applies contracts, capabilities, policy, approvals, runtime,
 * and evidence handling.
 */
export function createCusimanseMcpServer(operator: OperatorPort): McpServer {
  const server = new McpServer({ name: "cusimanse", version: "0.3.0" });

  if (isResearchSessionPort(operator)) {
    server.registerTool(
      "create_research_session",
      {
        description: "Create a governed Cusimanse research session from a declarative YAML/JSON recipe object.",
        inputSchema: { recipe: z.record(z.string(), z.unknown()) },
      },
      async ({ recipe }) => ({
        content: [{ type: "text", text: JSON.stringify(await operator.createResearchSession({ recipe }), null, 2) }],
      }),
    );

    server.registerTool(
      "complete_research",
      {
        description: "Mark a Cusimanse research session complete without bypassing runtime governance.",
        inputSchema: { experimentId: z.string().min(1) },
      },
      async ({ experimentId }) => ({
        content: [{ type: "text", text: JSON.stringify(await operator.completeResearch(experimentId), null, 2) }],
      }),
    );
  }

  server.registerTool(
    "research_state",
    {
      description: "Read the current state of a registered Cusimanse research session.",
      inputSchema: { experimentId: z.string().min(1) },
    },
    async ({ experimentId }) => ({
      content: [{ type: "text", text: JSON.stringify(await operator.getState(experimentId), null, 2) }],
    }),
  );

  server.registerTool(
    "research_evidence",
    {
      description: "Read recorded evidence references for a registered Cusimanse research session.",
      inputSchema: { experimentId: z.string().min(1) },
    },
    async ({ experimentId }) => ({
      content: [{ type: "text", text: JSON.stringify(await operator.getEvidence(experimentId), null, 2) }],
    }),
  );

  server.registerTool(
    "research_propose",
    {
      description: "Submit a structured research proposal to Cusimanse. Validation and governed execution remain inside Cusimanse.",
      inputSchema: {
        experimentId: z.string().min(1),
        proposal: reasoningProposalSchema,
      },
    },
    async ({ experimentId, proposal }) => ({
      content: [{ type: "text", text: JSON.stringify(await operator.submitProposal({ experimentId, proposal }), null, 2) }],
    }),
  );

  return server;
}

export async function serveCusimanseMcp(operator: OperatorPort): Promise<void> {
  await createCusimanseMcpServer(operator).connect(new StdioServerTransport());
}

function isResearchSessionPort(operator: OperatorPort): operator is ResearchSessionPort {
  return typeof (operator as Partial<ResearchSessionPort>).createResearchSession === "function" &&
    typeof (operator as Partial<ResearchSessionPort>).completeResearch === "function";
}
