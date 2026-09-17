import { describe, expect, it } from "vitest";
import { createGatewayModel, createGatewayProviderOptions } from "../../src/ai/gateway.js";
import { VercelSandboxComputeProvider } from "../../src/adapters/compute/vercel-sandbox.js";
import { registerVercelTelemetry, isVercelTelemetryRegistered } from "../../src/observability/vercel.js";

describe("Vercel-native runtime seams", () => {
  it("requires provider/model identifiers for AI Gateway", () => {
    expect(() => createGatewayModel({ primary: "gpt-5" })).toThrow(/provider\/model/);
  });

  it("builds ordered Gateway fallback options", () => {
    expect(createGatewayProviderOptions({
      primary: "openai/gpt-5.5",
      fallbacks: ["anthropic/claude-sonnet-4.6", "google/gemini-3-pro"],
      providers: ["openai", "anthropic"],
      tags: ["security-research"],
    })).toEqual({
      gateway: {
        models: ["anthropic/claude-sonnet-4.6", "google/gemini-3-pro"],
        order: ["openai", "anthropic"],
        tags: ["security-research"],
      },
    });
  });

  it("keeps Sandbox unavailable until Vercel credentials are present", async () => {
    const provider = new VercelSandboxComputeProvider();
    const token = process.env.VERCEL_TOKEN;
    const oidc = process.env.VERCEL_OIDC_TOKEN;
    delete process.env.VERCEL_TOKEN;
    delete process.env.VERCEL_OIDC_TOKEN;
    await expect(provider.isAvailable()).resolves.toBe(false);
    if (token !== undefined) process.env.VERCEL_TOKEN = token;
    if (oidc !== undefined) process.env.VERCEL_OIDC_TOKEN = oidc;
  });

  it("registers AI SDK telemetry only once", () => {
    registerVercelTelemetry();
    registerVercelTelemetry();
    expect(isVercelTelemetryRegistered()).toBe(true);
  });
});
