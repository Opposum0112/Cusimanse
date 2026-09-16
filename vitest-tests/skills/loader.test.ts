import { describe, expect, it } from "vitest";
import { loadValidatedSkills } from "../../src/skills/loader.js";

describe("validated skill loader", () => {
  it("loads declarative skills as native tools", async () => {
    const tools = await loadValidatedSkills();
    expect(tools["process-observation"]).toBeDefined();
  });
});
