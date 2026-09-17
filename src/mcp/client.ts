import { createMCPClient } from "@ai-sdk/mcp";
import type { ToolSet } from "ai";

export interface MCPServerConfig {
  name: string;
  url: string;
  headers?: Record<string, string>;
}

export interface MCPToolSource {
  name: string;
  tools: ToolSet;
  close(): Promise<void>;
}

/**
 * Connects external MCP research capabilities to the Cusimanse agent surface.
 * Callers must still wrap the returned tools with the Cusimanse policy boundary
 * before exposing them to an autonomous agent.
 */
export async function connectMCPResearchSource(config: MCPServerConfig): Promise<MCPToolSource> {
  const client = await createMCPClient({
    transport: {
      type: "http",
      url: config.url,
      ...(config.headers === undefined ? {} : { headers: config.headers }),
    },
    name: `cusimanse-${config.name}`,
    version: "0.4.0",
  });
  try {
    const tools = await client.tools();
    return { name: config.name, tools, close: () => client.close() };
  } catch (error) {
    await client.close();
    throw error;
  }
}
