import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { parseStraceRequest, parseSysdigRequest, InstrumentationError } from "../../src/adapters/instrumentation.js";

describe("instrumentation requests", () => {
  it("accepts allowlisted strace targets under /workspace", () => {
    const request = parseStraceRequest({
      target: "npm",
      durationSeconds: 20,
      outputPath: "/workspace/evidence/strace.out",
    });
    assert.equal(request.target, "npm");
    assert.equal(request.durationSeconds, 20);
  });

  it("rejects free-form strace targets and paths", () => {
    assert.throws(() => parseStraceRequest({ target: "bash", durationSeconds: 5, outputPath: "/workspace/x" }), InstrumentationError);
    assert.throws(() => parseStraceRequest({ target: "npm", durationSeconds: 5, outputPath: "/etc/passwd" }), InstrumentationError);
  });

  it("accepts named sysdig profiles only", () => {
    const request = parseSysdigRequest({
      profile: "network",
      durationSeconds: 15,
      outputPath: "/workspace/evidence/sysdig.scap",
    });
    assert.equal(request.profile, "network");
  });

  it("rejects raw sysdig filter strings as profile", () => {
    assert.throws(
      () => parseSysdigRequest({ profile: "proc.name=bash", durationSeconds: 10, outputPath: "/workspace/evidence/x" }),
      InstrumentationError,
    );
  });
});
