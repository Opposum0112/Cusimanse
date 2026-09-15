import type { CapabilityIntent } from "../../src/ir/index.js";
import { strict as assert } from "node:assert";
import { buildDependencyGraph, getReadyIntents, planExecution, PlannerError } from "../../src/planner/index.js";

const makeIr = (intents: CapabilityIntent[]) => ({
  version: "v1" as const,
  experimentId: "planner-test",
  source: { format: "yaml" as const, path: "test.yaml" },
  intents,
});

const intent = (id: string, dependsOn: string[] = []): CapabilityIntent => ({
  id,
  capability: `test.${id}`,
  parameters: {},
  dependsOn,
});

assert.deepEqual(
  planExecution(makeIr([intent("a"), intent("b", ["a"]), intent("c", ["b"])] )).orderedIntentIds,
  ["a", "b", "c"],
);

assert.deepEqual(
  planExecution(makeIr([intent("c", ["a"]), intent("a"), intent("b", ["a"])] )).orderedIntentIds,
  ["a", "b", "c"],
);

const graph = buildDependencyGraph(makeIr([intent("a"), intent("b", ["a"]), intent("c")]));
assert.deepEqual(getReadyIntents(makeIr([intent("a"), intent("b", ["a"]), intent("c")]), new Set(["a"])).map((x) => x.id), ["b", "c"]);
assert.deepEqual(graph.dependencies.b, ["a"]);

assert.throws(() => buildDependencyGraph(makeIr([intent("a"), intent("a")])), (error: unknown) => {
  return error instanceof PlannerError && error.issues.some((x) => x.includes("duplicate intent id"));
});

assert.throws(() => buildDependencyGraph(makeIr([intent("a", ["missing"])])), (error: unknown) => {
  return error instanceof PlannerError && error.issues.some((x) => x.includes("missing intent"));
});

assert.throws(() => buildDependencyGraph(makeIr([intent("a", ["a"])])), PlannerError);
assert.throws(() => planExecution(makeIr([intent("a", ["b"]), intent("b", ["a"])])), (error: unknown) => {
  return error instanceof PlannerError && error.message.includes("Dependency cycle detected");
});
