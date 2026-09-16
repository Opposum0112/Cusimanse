import { AdapterRegistry } from "../adapters/index.js";
import { createCapabilityRegistry, type CapabilityDescriptor } from "../capabilities/index.js";
import { compileRecipe } from "../compiler/index.js";
import { CARGateway, type CARGatewayOptions } from "../gateway/server.js";
import type { Reasoner } from "../llm/index.js";
import { OperationEngine } from "../operations/index.js";
import { ApprovalManager, PolicyEngine, type PolicyRule } from "../policy/index.js";
import { RuntimeOrchestrator } from "../runtime/index.js";
import { createResearchState } from "../state/index.js";
import type { Adapter } from "../adapters/index.js";

export class LabError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "LabError";
  }
}

export interface CreateLabOptions {
  contract: unknown;
  contractPath?: string;
  policy: PolicyRule[];
  capabilities: CapabilityDescriptor[];
  adapters: Adapter[];
  /** In-process proposal adapter (VercelAIReasoner or any Reasoner). */
  reasoner?: Reasoner;
  /** When true, start the HTTP operator ABI. Required if reasoner is omitted. */
  gateway?: boolean;
  listen?: CARGatewayOptions;
}

export interface LabHandle {
  experimentId: string;
  runtime: RuntimeOrchestrator;
  gateway?: CARGateway;
}

export function createLab(options: CreateLabOptions): LabHandle {
  if (!options.reasoner && options.gateway !== true) {
    throw new LabError("A lab requires an operator: pass reasoner and/or gateway: true.");
  }

  const ir = compileRecipe(options.contract, {
    format: "yaml",
    path: options.contractPath ?? "<memory>",
  });
  const capabilities = createCapabilityRegistry(options.capabilities);
  const policy = new PolicyEngine(options.policy);
  const adapters = new AdapterRegistry();
  for (const adapter of options.adapters) adapters.register(adapter);

  const runtime = new RuntimeOrchestrator({
    capabilities,
    policy,
    approvals: new ApprovalManager(),
    operations: new OperationEngine(),
    adapters,
    ...(options.reasoner ? { reasoner: options.reasoner } : {}),
  });

  const handle: LabHandle = { experimentId: ir.experimentId, runtime };

  if (options.gateway === true) {
    const gateway = new CARGateway(runtime);
    gateway.register({ ir, state: createResearchState(ir.experimentId) });
    gateway.listen(options.listen ?? { host: "127.0.0.1", port: 8787 });
    handle.gateway = gateway;
  }

  return handle;
}
