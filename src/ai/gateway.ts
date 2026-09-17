import { gateway, type LanguageModel } from "ai";

export interface GatewayModelConfig {
  primary: string;
  fallbacks?: string[];
  providers?: string[];
  tags?: string[];
}

/**
 * Central model policy for Cusimanse. Callers receive an AI SDK LanguageModel
 * while routing and fallback policy remain declarative and provider-neutral.
 */
export function createGatewayModel(config: GatewayModelConfig): LanguageModel {
  if (!config.primary.includes("/")) {
    throw new Error(`AI Gateway model must use provider/model form: ${config.primary}`);
  }

  // Gateway routing options are supplied per request by the agent layer. Keep
  // this factory deliberately small so model selection never becomes coupled
  // to a concrete provider SDK.
  return gateway(config.primary);
}

export function createGatewayProviderOptions(config: GatewayModelConfig): {
  gateway: { models?: string[]; order?: string[]; tags?: string[] };
} {
  return {
    gateway: {
      ...(config.fallbacks?.length ? { models: config.fallbacks } : {}),
      ...(config.providers?.length ? { order: config.providers } : {}),
      ...(config.tags?.length ? { tags: config.tags } : {}),
    },
  };
}
