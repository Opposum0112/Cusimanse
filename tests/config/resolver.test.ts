import { describe, expect, it } from "vitest";
import { resolveConfig } from "../../src/config/index.js";

describe("configuration resolver", () => {
  it("gives CLI values precedence", async () => {
    const previous = process.env.OPENAI_API_KEY;
    process.env.OPENAI_API_KEY = "env-secret";
    try {
      const config = await resolveConfig({ model: "gpt-test", apiKey: "cli-secret", baseUrl: "http://example.invalid/v1" }, process.cwd());
      expect(config.model).toBe("gpt-test"); expect(config.apiKey).toBe("cli-secret"); expect(config.baseUrl).toBe("http://example.invalid/v1"); expect(config.source.apiKey).toBe("cli");
    } finally { if (previous === undefined) delete process.env.OPENAI_API_KEY; else process.env.OPENAI_API_KEY = previous; }
  });
});
