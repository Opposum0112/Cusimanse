import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import type { RuntimeOrchestrator } from "../runtime/index.js";
import type { CusimanseIR } from "../ir/index.js";
import type { ResearchState } from "../state/index.js";
import { reasoningProposalSchema } from "../llm/index.js";
import type { OperatorPort } from "./contracts.js";

export interface ResearchSession {
  ir: CusimanseIR;
  state: ResearchState;
}

export interface CARGatewayOptions {
  host?: string;
  port?: number;
}

export class CARGateway implements OperatorPort {
  private readonly sessions = new Map<string, ResearchSession>();

  constructor(private readonly runtime: RuntimeOrchestrator) {}

  register(session: ResearchSession): void {
    if (this.sessions.has(session.ir.experimentId)) {
      throw new Error(`Research session already registered: ${session.ir.experimentId}`);
    }
    this.sessions.set(session.ir.experimentId, session);
  }

  hasSession(experimentId: string): boolean {
    return this.sessions.has(experimentId);
  }

  async submitProposal(request: Parameters<OperatorPort["submitProposal"]>[0]): Promise<Awaited<ReturnType<OperatorPort["submitProposal"]>>> {
    const session = this.sessions.get(request.experimentId);
    if (!session) throw new Error(`Unknown research session: ${request.experimentId}`);
    const proposal = reasoningProposalSchema.parse(request.proposal);
    if (proposal.complete) {
      return { experimentId: request.experimentId, accepted: false, proposal };
    }
    if (!proposal.capability) {
      throw new Error("Proposal capability is required for CAR execution.");
    }

    const intent = {
      id: `op-${crypto.randomUUID()}`,
      capability: proposal.capability,
      parameters: proposal.parameters ?? {},
      dependsOn: [],
    };
    const executionIr: CusimanseIR = { ...session.ir, intents: [intent] };
    const result = await this.runtime.run(executionIr, session.state);
    session.ir = { ...session.ir, intents: [...session.ir.intents, intent] };
    session.state = result.state;
    return { experimentId: request.experimentId, accepted: true, proposal };
  }

  async getState(experimentId: string) {
    const session = this.sessions.get(experimentId);
    if (!session) throw new Error(`Unknown research session: ${experimentId}`);
    return { experimentId, state: session.state };
  }

  async getEvidence(experimentId: string) {
    const session = this.sessions.get(experimentId);
    if (!session) throw new Error(`Unknown research session: ${experimentId}`);
    return { experimentId, evidence: session.state.evidence };
  }

  listen(options: CARGatewayOptions = {}): ReturnType<typeof createServer> {
    const server = createServer((request, response) => {
      void this.handle(request, response);
    });
    server.listen(options.port ?? 8787, options.host ?? "127.0.0.1");
    return server;
  }

  private async handle(request: IncomingMessage, response: ServerResponse): Promise<void> {
    try {
      const url = new URL(request.url ?? "/", "http://localhost");
      const match = url.pathname.match(/^\/v1\/research\/([^/]+)(?:\/(state|evidence|proposals))?$/);
      if (!match) return this.json(response, 404, { error: "Not found" });
      const experimentId = decodeURIComponent(match[1] ?? "");
      const action = match[2];

      if (request.method === "GET" && action === "state") return this.json(response, 200, await this.getState(experimentId));
      if (request.method === "GET" && action === "evidence") return this.json(response, 200, await this.getEvidence(experimentId));
      if (request.method === "POST" && action === "proposals") {
        const body = await readJson(request);
        if (!isProposalBody(body)) return this.json(response, 400, { error: "Request body must contain a proposal object." });
        return this.json(response, 200, await this.submitProposal({ experimentId, proposal: body.proposal }));
      }
      return this.json(response, 405, { error: "Method not allowed" });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      const status = message.startsWith("Unknown research session") ? 404 : 400;
      return this.json(response, status, { error: message });
    }
  }

  private json(response: ServerResponse, status: number, body: unknown): void {
    response.writeHead(status, { "content-type": "application/json" });
    response.end(JSON.stringify(body));
  }
}

function isProposalBody(value: unknown): value is { proposal: unknown } {
  return typeof value === "object" && value !== null && "proposal" in value;
}

function readJson(request: IncomingMessage): Promise<unknown> {
  return new Promise((resolve, reject) => {
    let body = "";
    request.setEncoding("utf8");
    request.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1_000_000) reject(new Error("Request body too large."));
    });
    request.on("end", () => {
      try { resolve(JSON.parse(body || "{}")); } catch { reject(new Error("Invalid JSON.")); }
    });
    request.on("error", reject);
  });
}
