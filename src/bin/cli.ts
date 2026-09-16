#!/usr/bin/env node
import { readFile } from "node:fs/promises";
import { Command } from "commander";
import { parse } from "yaml";
import { compileRecipe } from "../compiler/index.js";
import { CARGateway } from "../gateway/server.js";
import { createResearchState } from "../state/index.js";
import { MockComputeProvider } from "../adapters/compute/mock.js";
import { ComputeProviderRegistry } from "../adapters/compute/index.js";
import type { Adapter } from "../adapters/index.js";
import { CapabilityRegistry } from "../capabilities/index.js";
import { PolicyEngine, ApprovalManager } from "../policy/index.js";
import { OperationEngine } from "../operations/index.js";
import { RuntimeOrchestrator } from "../runtime/index.js";
import { LocalExecutionRuntime, TemporalExecutionRuntime, GraphExecutionRuntime } from "../runtime/index.js";

const program = new Command();
program.name("cusimanse").description("Composable, harness-neutral security research runtime").version("0.3.0");

program.command("compile <recipe>")
  .description("Validate a declarative recipe and emit its intermediate representation")
  .action(async (recipePath: string) => {
    const recipe = await loadRecipe(recipePath);
    const ir = compileRecipe(recipe, { format: recipePath.endsWith(".json") ? "json" : "yaml", path: recipePath });
    process.stdout.write(`${JSON.stringify(ir, null, 2)}\n`);
  });

program.command("serve")
  .description("Start the operator gateway")
  .option("--port <number>", "HTTP port", "8787")
  .action(async (options: { port: string }) => {
    const gateway = new CARGateway({} as RuntimeOrchestrator);
    gateway.listen({ host: "127.0.0.1", port: Number(options.port) });
    console.log(`Cusimanse gateway listening on http://127.0.0.1:${options.port}`);
  });

program.command("run <recipe>")
  .description("Run a validated recipe through a selected execution runtime and compute provider")
  .option("--runtime <runtime>", "local, temporal, or graph", "local")
  .option("--provider <provider>", "lima, multipass, cloud, or mock", "mock")
  .action(async (recipePath: string, options: { runtime: string; provider: string }) => {
    const recipe = await loadRecipe(recipePath);
    const ir = compileRecipe(recipe, { format: recipePath.endsWith(".json") ? "json" : "yaml", path: recipePath });
    const compute = new ComputeProviderRegistry();
    compute.register(new MockComputeProvider());
    const provider = compute.get(options.provider);
    if (!(await provider.isAvailable())) throw new Error(`Compute provider unavailable: ${options.provider}`);

    const capabilities = new CapabilityRegistry();
    for (const intent of ir.intents) capabilities.register({ name: intent.capability, version: "v1", operationKinds: ["tool"] });
    const adapters = new Map<string, Adapter>();
    const adapter: Adapter = {
      name: "compute-runtime",
      capabilities: ir.intents.map((intent) => intent.capability),
      async execute(context, parameters) {
        const command = typeof parameters.command === "string" ? parameters.command : "true";
        const args = Array.isArray(parameters.args) ? parameters.args.filter((x): x is string => typeof x === "string") : [];
        const result = await provider.exec(command, args);
        return { status: result.exitCode === 0 ? "succeeded" : "failed", output: result, error: result.stderr || undefined, evidenceRefs: [`evidence://${ir.experimentId}/${context.operationId}`] };
      },
    };
    adapters.set(adapter.name, adapter);
    const registry = new (await import("../adapters/index.js")).AdapterRegistry();
    registry.register(adapter);
    const policy = new PolicyEngine(ir.intents.map((intent) => ({ id: `allow-${intent.id}`, capability: intent.capability, decision: "allow", reason: "Recipe capability" })));
    const dependencies = { capabilities, policy, approvals: new ApprovalManager(), operations: new OperationEngine(), adapters: registry };
    const runtimes = { local: new LocalExecutionRuntime(dependencies), temporal: new TemporalExecutionRuntime(), graph: new GraphExecutionRuntime() };
    const runtime = runtimes[options.runtime as keyof typeof runtimes];
    if (!runtime) throw new Error(`Unknown runtime: ${options.runtime}`);
    const state = await runtime.run(ir, createResearchState(ir.experimentId), { runId: crypto.randomUUID() });
    process.stdout.write(`${JSON.stringify(state, null, 2)}\n`);
  });

const skills = program.command("skills").description("Manage skill lifecycle");
skills.command("promote <candidateDir>")
  .description("Validate a candidate skill and report promotion eligibility")
  .action(async (candidateDir: string) => {
    const required = ["SKILL.md", "skill.yaml"];
    const { access } = await import("node:fs/promises");
    for (const file of required) await access(`${candidateDir}/${file}`);
    console.log(`Skill candidate ${candidateDir} passed structural validation; promotion requires repository policy review.`);
  });

async function loadRecipe(path: string): Promise<unknown> {
  return parse(await readFile(path, "utf8"));
}

await program.parseAsync(process.argv);
