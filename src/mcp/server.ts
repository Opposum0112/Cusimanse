import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import type { OperatorPort } from "../gateway/contracts.js";
import { reasoningProposalSchema } from "../llm/index.js";

/**
 * Build the MCP adapter over the harness-neutral OperatorPort.
 *
 * MCP is intentionally only the interoperability boundary. It never exposes
 * arbitrary shell/process execution; executable requests cross OperatorPort,
 * where Cusimanse applies contracts, capabilities, policy, approvals, runtime,
 * and evidence handling.
 */
export function createCusimanseMcpServer(operator: OperatorPort): McpServer {
  const server = new McpServer({ name: "cusimanse", version: "0.3.0" });

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
      description:
        "Submit a structured research proposal to Cusimanse. The proposal is validated and governed by the runtime; this tool does not provide arbitrary shell or process execution.",
      inputSchema: {
        experimentId: z.string().min(1),
        proposal: reasoningProposalSchema,
      },
    },
    async ({ experimentId, proposal }) => ({
      content: [
        {
          type: "text",
          text: JSON.stringify(await operator.submitProposal({ experimentId, proposal }), null, 2),
        },
      ],
    }),
  );

  return server;
}

/** Start the local MCP transport used by MCP-capable agent harnesses. */
export async function serveCusimanseMcp(operator: OperatorPort): Promise<void> {
  await createCusimanseMcpServer(operator).connect(new StdioServerTransport());
}
