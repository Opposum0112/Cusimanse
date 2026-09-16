import { createAnthropic } from "@ai-sdk/anthropic";
import { createGoogleGenerativeAI } from "@ai-sdk/google";
import { createOpenAI } from "@ai-sdk/openai";
import type { LanguageModel } from "ai";
import type { ResolvedConfig } from "../config/index.js";
export interface ModelRequest { provider: ResolvedConfig["provider"]; model: string; apiKey?: string; baseUrl?: string; }
export function getModel(provider: string, modelName: string, credentials: { apiKey?: string; baseUrl?: string } = {}): LanguageModel {
  if (provider === "anthropic") return createAnthropic(credentials.apiKey === undefined ? {} : { apiKey: credentials.apiKey })(modelName);
  if (provider === "google") return createGoogleGenerativeAI(credentials.apiKey === undefined ? {} : { apiKey: credentials.apiKey })(modelName);
  if (provider === "ollama" || provider === "deepseek") { const baseURL = credentials.baseUrl ?? (provider === "ollama" ? "http://127.0.0.1:11434/v1" : "https://api.deepseek.com/v1"); return createOpenAI({ baseURL, apiKey: credentials.apiKey ?? "local" }).chat(modelName); }
  return createOpenAI(credentials.apiKey === undefined ? {} : { apiKey: credentials.apiKey })(modelName);
}
export function modelFromConfig(config: ResolvedConfig): LanguageModel { return getModel(config.provider, config.model, { ...(config.apiKey === undefined ? {} : { apiKey: config.apiKey }), ...(config.baseUrl === undefined ? {} : { baseUrl: config.baseUrl }) }); }
