import { gateway, type LanguageModel } from "ai";

export interface GatewayModelConfig {
  primary: string;
  fallbacks?: string[];
  providers?: string[];
  /**
   * Retained as domain metadata for future routing policy; AI Gateway does
   * not currently expose tags under providerOptions.gateway.
   */
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
  return gateway(config.primary);
}

export function createGatewayProviderOptions(config: GatewayModelConfig): {
  gateway: { models?: string[]; order?: string[] };
} {
  return {
    gateway: {
      ...(config.fallbacks?.length ? { models: config.fallbacks } : {}),
      ...(config.providers?.length ? { order: config.providers } : {}),
    },
  };
}
