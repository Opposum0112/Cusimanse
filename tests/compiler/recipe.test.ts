import { strict as assert } from "node:assert";
import { compileRecipe, RecipeValidationError } from "../../src/compiler/index.js";

const recipe = compileRecipe({
  api_version: "v1",
  kind: "ExperimentRecipe",
  experiment_id: "test",
  intents: [{ id: "one", capability: "vm.create", parameters: { provider: "lima" }, depends_on: [] }],
});

assert.equal(recipe.experimentId, "test");
assert.equal(recipe.intents[0]?.capability, "vm.create");

try {
  compileRecipe({ api_version: "v1", kind: "ExperimentRecipe", intents: [] });
  assert.fail("expected validation error");
} catch (error) {
  assert.ok(error instanceof RecipeValidationError);
}
