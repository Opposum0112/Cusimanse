import { describe, expect, it } from "node:test";
import { WorkloadAdapters } from "../../src/adapters/workloads.js";

describe("workload adapter contracts", () => {
  it("keeps workload execution behind injected adapters", async () => {
    let installed = "";
    const adapters = new WorkloadAdapters(
      { execute: async () => ({ stdout: "", stderr: "", exitCode: 0 }) },
      { read: async () => "", write: async () => {} },
      { list: async () => [] },
      { install: async (dir) => { installed = dir; return { stdout: "ok", stderr: "", exitCode: 0 }; } },
    );
    await adapters.npm.install("/workspace");
    expect(installed).toBe("/workspace");
  });
});
