import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import type { CARGateway } from "../gateway/server.js";

export function createCusimanseMcpServer(gateway: CARGateway): McpServer {
  const server = new McpServer({ name: "cusimanse", version: "0.3.0" });
  server.registerTool("research_state", {
    description: "Read the current state of a registered Cusimanse research session.",
    inputSchema: { experimentId: z.string().min(1) },
  }, async ({ experimentId }) => ({
    content: [{ type: "text", text: JSON.stringify(await gateway.getState(experimentId), null, 2) }],
  }));
  server.registerTool("research_evidence", {
    description: "Read sealed/recorded evidence references for a registered research session.",
    inputSchema: { experimentId: z.string().min(1) },
  }, async ({ experimentId }) => ({
    content: [{ type: "text", text: JSON.stringify(await gateway.getEvidence(experimentId), null, 2) }],
  }));
  return server;
}

export async function serveCusimanseMcp(gateway: CARGateway): Promise<void> {
  await createCusimanseMcpServer(gateway).connect(new StdioServerTransport());
}
