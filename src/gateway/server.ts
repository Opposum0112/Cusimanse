import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import type { RuntimeOrchestrator } from "../runtime/index.js";
import type { CusimanseIR } from "../ir/index.js";
import type { ResearchState } from "../state/index.js";
import { reasoningProposalSchema, type ReasoningProposal } from "../llm/index.js";
import type { OperatorPort, ResearchSessionPort } from "./contracts.js";
import { compileRecipe } from "../compiler/index.js";
import { createResearchState } from "../state/index.js";

export interface ResearchSession { ir: CusimanseIR; state: ResearchState; }
export interface CARGatewayOptions { host?: string; port?: number; }
export type RuntimeFactory = (ir: CusimanseIR) => Promise<RuntimeOrchestrator>;

export class CARGateway implements ResearchSessionPort {
  private readonly sessions = new Map<string, ResearchSession>();
  private readonly sessionRuntimes = new Map<string, RuntimeOrchestrator>();
  constructor(private readonly runtime?: RuntimeOrchestrator, private readonly runtimeFactory?: RuntimeFactory) {}

  register(session: ResearchSession, runtime: RuntimeOrchestrator = this.runtime as RuntimeOrchestrator): void {
    if (this.sessions.has(session.ir.experimentId)) throw new Error(`Research session already registered: ${session.ir.experimentId}`);
    if (!runtime) throw new Error("Execution runtime is not configured for this gateway.");
    this.sessions.set(session.ir.experimentId, session);
    this.sessionRuntimes.set(session.ir.experimentId, runtime);
  }
  hasSession(experimentId: string): boolean { return this.sessions.has(experimentId); }

  async createResearchSession(request: { recipe: unknown }): Promise<{ experimentId: string; state: ResearchState }> {
    const ir = compileRecipe(request.recipe);
    if (this.sessions.has(ir.experimentId)) throw new Error(`Research session already registered: ${ir.experimentId}`);
    const runtime = this.runtime ?? (this.runtimeFactory ? await this.runtimeFactory(ir) : undefined);
    if (!runtime) throw new Error("Execution runtime is not configured for this gateway.");
    const state = createResearchState(ir.experimentId);
    this.register({ ir, state }, runtime);
    return { experimentId: ir.experimentId, state };
  }

  async completeResearch(experimentId: string): Promise<{ experimentId: string; state: ResearchState }> {
    const session = this.sessions.get(experimentId);
    if (!session) throw new Error(`Unknown research session: ${experimentId}`);
    const state = { ...session.state, phase: "completed" as const, revision: session.state.revision + 1 };
    session.state = state;
    return { experimentId, state };
  }

  async submitProposal(request: Parameters<OperatorPort["submitProposal"]>[0]): Promise<Awaited<ReturnType<OperatorPort["submitProposal"]>>> {
    const session = this.sessions.get(request.experimentId);
    if (!session) throw new Error(`Unknown research session: ${request.experimentId}`);
    const proposal = reasoningProposalSchema.parse(request.proposal);
    if (proposal.complete) return { experimentId: request.experimentId, accepted: false, proposal };
    const runtime = this.sessionRuntimes.get(request.experimentId);
    if (!runtime) throw new Error("Execution runtime is not configured for this gateway.");
    if (!proposal.capability) throw new Error("Proposal capability is required for CAR execution.");
    const intent = { id: `op-${crypto.randomUUID()}`, capability: proposal.capability, parameters: proposal.parameters ?? {}, dependsOn: [] };
    const executionIr: CusimanseIR = { ...session.ir, intents: [intent] };
    const result = await runtime.run(executionIr, session.state);
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
    const server = createServer((request, response) => { void this.handle(request, response); });
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
        const body = await readJson(request); const proposal = parseProposalBody(body);
        if (!proposal) return this.json(response, 400, { error: "Request body must contain a proposal object." });
        return this.json(response, 200, await this.submitProposal({ experimentId, proposal }));
      }
      return this.json(response, 405, { error: "Method not allowed" });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      const status = message.startsWith("Unknown research session") ? 404 : 400;
      return this.json(response, status, { error: message });
    }
  }
  private json(response: ServerResponse, status: number, body: unknown): void { response.writeHead(status, { "content-type": "application/json" }); response.end(JSON.stringify(body)); }
}
function parseProposalBody(value: unknown): ReasoningProposal | undefined {
  if (typeof value !== "object" || value === null || !("proposal" in value)) return undefined;
  const parsed = reasoningProposalSchema.safeParse((value as { proposal: unknown }).proposal);
  return parsed.success ? parsed.data : undefined;
}
function readJson(request: IncomingMessage): Promise<unknown> {
  return new Promise((resolve, reject) => {
    let body = "";
    request.setEncoding("utf8");
    request.on("data", (chunk) => { body += chunk; if (body.length > 1_000_000) reject(new Error("Request body too large.")); });
    request.on("end", () => { try { resolve(JSON.parse(body || "{}")); } catch { reject(new Error("Invalid JSON.")); } });
    request.on("error", reject);
  });
}
