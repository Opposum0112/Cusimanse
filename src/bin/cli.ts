#!/usr/bin/env node
import { readFile, writeFile } from "node:fs/promises";
import { Command } from "commander";
import { parse } from "yaml";
import { compileRecipe } from "../compiler/index.js";
import { CARGateway } from "../gateway/server.js";
import { getComputeProvider } from "../adapters/compute/factory.js";
import { getExperimentRuntime } from "../runtime/factory.js";
import { resolveConfig } from "../config/index.js";
import { promoteSkill } from "../skills/lifecycle.js";
const program = new Command();
program.name("cusimanse").description("Harness-neutral declarative security research runtime").version("0.4.0");
function commonOptions(command: Command): Command { return command.option("--model <model>", "LLM model name").option("--api-key <key>", "LLM API key").option("--base-url <url>", "OpenAI-compatible base URL"); }
commonOptions(program.command("run <recipe>").description("Compile and execute a recipe").option("-p, --provider <provider>", "lima, multipass, cloud, or mock", "mock").option("-r, --runtime <runtime>", "local, temporal, or graph", "local").option("-v, --verbose", "verbose progress")).action(async (recipePath: string, options: { provider: string; runtime: string; verbose?: boolean; model?: string; apiKey?: string; baseUrl?: string }) => { const recipe = parse(await readFile(recipePath, "utf8")); const ir = compileRecipe(recipe, { format: recipePath.endsWith(".json") ? "json" : "yaml", path: recipePath }); const config = await resolveConfig(options); const compute = await getComputeProvider(options.provider); const runtime = getExperimentRuntime(options.runtime); const result = await runtime.execute({ runId: crypto.randomUUID(), ir, compute, onStepProgress: options.verbose ? (stepId: string, status: "pending" | "running" | "completed" | "failed") => console.error(`[${status}] ${stepId}`) : undefined }); process.stdout.write(`${JSON.stringify({ config: { provider: config.provider, model: config.model }, run: result }, null, 2)}\n`); if (!result.success) process.exitCode = 1; });
commonOptions(program.command("compile <recipe>").description("Validate YAML/JSON and emit compiled IR").option("-o, --output <path>", "write IR to a file")).action(async (recipePath: string, options: { output?: string }) => { const recipe = parse(await readFile(recipePath, "utf8")); const ir = compileRecipe(recipe, { format: recipePath.endsWith(".json") ? "json" : "yaml", path: recipePath }); const text = `${JSON.stringify(ir, null, 2)}\n`; if (options.output) await writeFile(options.output, text, "utf8"); else process.stdout.write(text); });
program.command("serve").description("Start Operator ABI Gateway (JSON-RPC/REST/SSE)").option("-p, --port <port>", "HTTP port", "8080").option("-h, --host <host>", "bind host", "127.0.0.1").action((options: { port: string; host: string }) => { const gateway = new CARGateway(); gateway.listen({ host: options.host, port: Number(options.port) }); console.log(`Cusimanse gateway listening on http://${options.host}:${options.port}`); });
program.command("skills").description("Manage dynamic validated skills").command("promote <candidateDir>").description("Validate and promote a candidate skill").action(async (candidateDir: string) => { const result = await promoteSkill(candidateDir); console.log(`Promoted ${result.id} -> ${result.path}`); });
await program.parseAsync(process.argv);
