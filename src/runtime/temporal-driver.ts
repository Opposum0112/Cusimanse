import { Client, Connection } from "@temporalio/client";
import type { ExperimentRuntime, RuntimeContext, ExecutionResult } from "./spi/types.js";
import { executeResearchRun, type TemporalResearchRunResult } from "./temporal/workflow.js";

export interface TemporalRuntimeOptions {
  address?: string;
  namespace?: string;
  taskQueue?: string;
}

export class TemporalDurableRuntime implements ExperimentRuntime {
  readonly id = "temporal" as const;
  private readonly options: Required<TemporalRuntimeOptions>;
  private connection?: Connection;
  private client?: Client;
  private readonly runs = new Map<string, { workflowId: string; state?: TemporalResearchRunResult["state"] }>();

  constructor(options: TemporalRuntimeOptions = {}) {
    this.options = {
      address: options.address ?? process.env.TEMPORAL_ADDRESS ?? "localhost:7233",
      namespace: options.namespace ?? process.env.TEMPORAL_NAMESPACE ?? "default",
      taskQueue: options.taskQueue ?? process.env.CUSIMANSE_TEMPORAL_TASK_QUEUE ?? "cusimanse-research",
    };
  }

  private async getClient(): Promise<Client> {
    if (this.client) return this.client;
    this.connection = await Connection.connect({ address: this.options.address });
    this.client = new Client({ connection: this.connection, namespace: this.options.namespace });
    return this.client;
  }

  async execute(ctx: RuntimeContext): Promise<ExecutionResult> {
    const client = await this.getClient();
    const workflowId = `cusimanse-${ctx.runId}`;
    this.runs.set(ctx.runId, { workflowId });
    const handle = await client.workflow.start(executeResearchRun, {
      workflowId,
      taskQueue: this.options.taskQueue,
      args: [{ runId: ctx.runId, ir: ctx.ir, providerId: ctx.compute.id }],
    });
    const result = await handle.result();
    const run = this.runs.get(ctx.runId);
    if (run) run.state = result.state;
    return result.execution;
  }

  getResearchState(runId: string): TemporalResearchRunResult["state"] | undefined {
    return this.runs.get(runId)?.state;
  }

  async abort(runId: string): Promise<void> {
    const run = this.runs.get(runId);
    if (!run || !this.client) return;
    await this.client.workflow.getHandle(run.workflowId).terminate("Cusimanse run aborted");
  }
}
