#!/usr/bin/env node
import { access, mkdir, readFile, rename } from "node:fs/promises";
import { basename, resolve, relative, join } from "node:path";
import { Command } from "commander";
import { parse } from "yaml";
import { compileRecipe } from "../compiler/index.js";
import { CARGateway } from "../gateway/server.js";
import { createResearchState } from "../state/index.js";
import { MockComputeProvider } from "../adapters/compute/mock.js";
import { ComputeProviderRegistry } from "../adapters/compute/index.js";
import { AdapterRegistry, type Adapter } from "../adapters/index.js";
import { CapabilityRegistry } from "../capabilities/index.js";
import { PolicyEngine, ApprovalManager } from "../policy/index.js";
import { OperationEngine } from "../operations/index.js";
import { LocalExecutionRuntime, TemporalExecutionRuntime, GraphExecutionRuntime } from "../runtime/index.js";

const program = new Command();
program.name("cusimanse").description("Composable, harness-neutral security research runtime").version("0.3.0");

program.command("compile <recipe>").description("Validate a declarative recipe and emit its intermediate representation").action(async (recipePath: string) => {
  const recipe = await loadRecipe(recipePath);
  const ir = compileRecipe(recipe, { format: recipePath.endsWith(".json") ? "json" : "yaml", path: recipePath });
  process.stdout.write(`${JSON.stringify(ir, null, 2)}\n`);
});

program.command("serve").description("Start the operator gateway").option("--port <number>", "HTTP port", "8787").action(async (options: { port: string }) => {
  const gateway = new CARGateway();
  gateway.listen({ host: "127.0.0.1", port: Number(options.port) });
  console.log(`Cusimanse gateway listening on http://127.0.0.1:${options.port}`);
});

program.command("run <recipe>").description("Run a validated recipe through a selected execution runtime and compute provider")
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
    const adapterRegistry = new AdapterRegistry();
    const adapter: Adapter = {
      name: "compute-runtime",
      capabilities: ir.intents.map((intent) => intent.capability),
      async execute(context, parameters) {
        const command = typeof parameters.command === "string" ? parameters.command : "true";
        const args = Array.isArray(parameters.args) ? parameters.args.filter((x): x is string => typeof x === "string") : [];
        const result = await provider.exec(command, args);
        const execution: { status: "succeeded" | "failed"; output: typeof result; evidenceRefs: string[]; error?: string } = {
          status: result.exitCode === 0 ? "succeeded" : "failed",
          output: result,
          evidenceRefs: [`evidence://${ir.experimentId}/${context.operationId}`],
        };
        if (result.stderr) execution.error = result.stderr;
        return execution;
      },
    };
    adapterRegistry.register(adapter);
    const policy = new PolicyEngine(ir.intents.map((intent) => ({ id: `allow-${intent.id}`, capability: intent.capability, decision: "allow", reason: "Recipe capability" })));
    const dependencies = { capabilities, policy, approvals: new ApprovalManager(), operations: new OperationEngine(), adapters: adapterRegistry };
    const runtimes = { local: new LocalExecutionRuntime(dependencies), temporal: new TemporalExecutionRuntime(), graph: new GraphExecutionRuntime() };
    const runtime = runtimes[options.runtime as keyof typeof runtimes];
    if (!runtime) throw new Error(`Unknown runtime: ${options.runtime}`);
    const state = await runtime.run(ir, createResearchState(ir.experimentId), { runId: crypto.randomUUID() });
    process.stdout.write(`${JSON.stringify(state, null, 2)}\n`);
  });

const skills = program.command("skills").description("Manage skill lifecycle");
skills.command("promote <candidateDir>").description("Validate and promote a candidate skill into the validated lifecycle stage").action(async (candidateDir: string) => {
  const source = resolve(candidateDir);
  const candidateRoot = resolve("skills/candidate");
  const validatedRoot = resolve("skills/validated");
  const rel = relative(candidateRoot, source);
  if (!rel || rel.startsWith("..") || rel.includes(".." + "/")) throw new Error("Candidate must live under skills/candidate.");
  for (const file of ["SKILL.md", "skill.yaml"]) await access(join(source, file));
  const manifest = parse(await readFile(join(source, "skill.yaml"), "utf8")) as Record<string, unknown>;
  if (typeof manifest.name !== "string" || typeof manifest.version !== "string" || typeof manifest.capability !== "string") {
    throw new Error("skill.yaml requires name, version, and capability.");
  }
  const destination = join(validatedRoot, basename(source));
  await mkdir(validatedRoot, { recursive: true });
  await rename(source, destination);
  console.log(`Promoted ${source} -> ${destination}`);
});

async function loadRecipe(path: string): Promise<unknown> { return parse(await readFile(path, "utf8")); }
await program.parseAsync(process.argv);
