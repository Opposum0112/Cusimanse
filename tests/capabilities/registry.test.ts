import test from "node:test";
import assert from "node:assert/strict";
import {
  CapabilityRegistry,
  CapabilityResolutionError,
  createCapabilityRegistry,
} from "../../src/capabilities/index.js";

test("registers and resolves a capability deterministically", () => {
  const registry = createCapabilityRegistry([
    { name: "workload.npm.install", version: "v1", operationKinds: ["tool"] },
    { name: "vm.create", version: "v1", operationKinds: ["vm"] },
  ]);

  const resolved = registry.resolve("workload.npm.install", { workingDirectory: "/workspace" });

  assert.equal(resolved.descriptor.name, "workload.npm.install");
  assert.equal(resolved.descriptor.version, "v1");
  assert.deepEqual(resolved.parameters, { workingDirectory: "/workspace" });
  assert.deepEqual(registry.list().map((capability) => capability.name), [
    "vm.create",
    "workload.npm.install",
  ]);
});

test("rejects duplicate capability registration", () => {
  const registry = new CapabilityRegistry();
  registry.register({ name: "vm.create", version: "v1", operationKinds: ["vm"] });

  assert.throws(
    () => registry.register({ name: "vm.create", version: "v2", operationKinds: ["vm"] }),
    (error: unknown) =>
      error instanceof CapabilityResolutionError &&
      error.message === "Capability already registered: vm.create",
  );
});

test("rejects unknown capabilities", () => {
  const registry = new CapabilityRegistry();

  assert.throws(
    () => registry.resolve("shell.execute", { command: "echo test" }),
    (error: unknown) =>
      error instanceof CapabilityResolutionError &&
      error.message === "Capability not registered: shell.execute" &&
      error.issues.includes("unresolved capability: shell.execute"),
  );
});

test("runs parameter validation before resolution", () => {
  const registry = new CapabilityRegistry();
  registry.register({
    name: "workload.npm.install",
    version: "v1",
    operationKinds: ["tool"],
    validateParameters: (parameters) => {
      if (typeof parameters.workingDirectory !== "string") {
        throw new Error("workingDirectory is required");
      }
    },
  });

  assert.throws(() => registry.resolve("workload.npm.install", {}), /workingDirectory is required/);
});
