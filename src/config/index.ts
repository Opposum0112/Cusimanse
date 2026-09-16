import { homedir } from "node:os";
import { readFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { parse } from "yaml";

export interface ResolverCliOptions {
  model?: string;
  apiKey?: string;
  baseUrl?: string;
}

export interface ResolvedConfig {
  provider: "openai" | "anthropic" | "google" | "ollama" | "deepseek";
  model: string;
  apiKey?: string;
  baseUrl?: string;
  source: { model: string; apiKey: string; baseUrl: string };
}

type ConfigFile = Partial<Pick<ResolvedConfig, "provider" | "model" | "apiKey" | "baseUrl">>;

const envKeys = {
  anthropic: "ANTHROPIC_API_KEY",
  openai: "OPENAI_API_KEY",
  google: "GEMINI_API_KEY",
  deepseek: "DEEPSEEK_API_KEY",
  ollama: "OLLAMA_BASE_URL",
} as const;

export async function resolveConfig(options: ResolverCliOptions = {}, cwd = process.cwd()): Promise<ResolvedConfig> {
  const project = await loadYaml(join(cwd, ".cusimanse", "config.yaml"));
  const user = await loadYaml(join(homedir(), ".cusimanse", "config.yaml"));
  const dotenv = await loadDotEnv(join(cwd, ".env"));
  const fileConfig: ConfigFile = { ...user, ...project };
  const environment = { ...dotenv, ...process.env };
  const provider = inferProvider(options.model ?? fileConfig.model ?? environment.CUSIMANSE_MODEL ?? "openai");
  const apiKey = options.apiKey ?? environment[envKeys[provider]] ?? fileConfig.apiKey;
  const baseUrl = options.baseUrl ?? environment[envKeys.ollama] ?? environment.CUSIMANSE_BASE_URL ?? fileConfig.baseUrl;
  const model = options.model ?? fileConfig.model ?? environment.CUSIMANSE_MODEL ?? defaultModel(provider);
  return {
    provider,
    model,
    ...(apiKey === undefined ? {} : { apiKey }),
    ...(baseUrl === undefined ? {} : { baseUrl }),
    source: {
      model: options.model ? "cli" : fileConfig.model ? "file" : environment.CUSIMANSE_MODEL ? "env" : "default",
      apiKey: options.apiKey ? "cli" : environment[envKeys[provider]] ? "env" : fileConfig.apiKey ? "file" : "none",
      baseUrl: options.baseUrl ? "cli" : environment[envKeys.ollama] || environment.CUSIMANSE_BASE_URL ? "env" : fileConfig.baseUrl ? "file" : "none",
    },
  };
}

function inferProvider(model: string): ResolvedConfig["provider"] {
  const normalized = model.toLowerCase();
  if (normalized.startsWith("claude")) return "anthropic";
  if (normalized.startsWith("gemini")) return "google";
  if (normalized.startsWith("deepseek")) return "deepseek";
  if (normalized.startsWith("ollama/") || normalized.includes("localhost") || normalized.includes("127.0.0.1")) return "ollama";
  return "openai";
}

function defaultModel(provider: ResolvedConfig["provider"]): string {
  if (provider === "anthropic") return "claude-sonnet-4-20250514";
  if (provider === "google") return "gemini-2.5-flash";
  if (provider === "deepseek") return "deepseek-chat";
  if (provider === "ollama") return "deepseek-r1";
  return "gpt-4.1-mini";
}

async function loadYaml(path: string): Promise<ConfigFile> {
  try {
    const raw = await readFile(path, "utf8");
    const parsed: unknown = parse(raw);
    if (typeof parsed !== "object" || parsed === null) return {};
    return parsed as ConfigFile;
  } catch {
    return {};
  }
}

async function loadDotEnv(path: string): Promise<Record<string, string>> {
  try {
    const raw = await readFile(resolve(path), "utf8");
    const result: Record<string, string> = {};
    for (const line of raw.split(/\r?\n/u)) {
      const match = line.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/u);
      if (!match) continue;
      const key = match[1];
      const value = match[2]?.replace(/^['"]|['"]$/gu, "");
      if (key && value !== undefined) result[key] = value;
    }
    return result;
  } catch {
    return {};
  }
}
