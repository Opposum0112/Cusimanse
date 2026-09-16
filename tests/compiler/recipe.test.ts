import { strict as assert } from "node:assert";
import test from "node:test";
import { compileRecipe, RecipeValidationError } from "../../src/compiler/index.js";

test("compiler accepts a minimal recipe and attaches a default contract", () => {
  const recipe = compileRecipe({
    api_version: "v1",
    kind: "ExperimentRecipe",
    experiment_id: "test",
    intents: [{ id: "one", capability: "vm.create", parameters: { provider: "lima" }, depends_on: [] }],
  });

  assert.equal(recipe.experimentId, "test");
  assert.equal(recipe.intents[0]?.capability, "vm.create");
  assert.equal(recipe.contract.contractVersion, "0.2");
  assert.equal(typeof recipe.contract.hash, "string");
});

test("compiler rejects a missing experiment_id", () => {
  try {
    compileRecipe({ api_version: "v1", kind: "ExperimentRecipe", intents: [] });
    assert.fail("expected validation error");
  } catch (error) {
    assert.ok(error instanceof RecipeValidationError);
  }
});

test("compiler rejects intents outside allowed_capabilities", () => {
  try {
    compileRecipe({
      api_version: "v1",
      kind: "ExperimentRecipe",
      experiment_id: "deny-extra",
      allowed_capabilities: ["vm.create"],
      intents: [{ id: "shell", capability: "host.shell", depends_on: [] }],
    });
    assert.fail("expected validation error");
  } catch (error) {
    assert.ok(error instanceof RecipeValidationError);
    assert.ok((error as RecipeValidationError).issues.some((issue) => issue.includes("allowed_capabilities")));
  }
});

test("compiler freezes question, evidence, and destroy clauses", () => {
  const recipe = compileRecipe({
    api_version: "v1",
    kind: "ExperimentRecipe",
    experiment_id: "npm-contract",
    contract_version: "0.2",
    research_question: {
      id: "rq-1",
      question: "What does npm install do?",
      non_goals: ["Do not persist the VM"],
    },
    scope: { hosts: ["disposable-vm"], paths: ["/workspace"], networks: ["declared-test-network"] },
    allowed_capabilities: ["vm.create", "workload.npm.install"],
    evidence_required: [{ type: "process", produced_by: "evidence.collect" }],
    stop_when: { all_evidence_required: true, max_proposals: 20 },
    destroy: { capability: "vm.destroy", require_evidence_sealed: true },
    intents: [{ id: "one", capability: "vm.create", depends_on: [] }],
  });

  assert.equal(recipe.contract.question?.nonGoals[0], "Do not persist the VM");
  assert.equal(recipe.contract.evidenceRequired[0]?.type, "process");
  assert.equal(recipe.contract.stopWhen.maxProposals, 20);
  assert.equal(recipe.contract.destroy?.requireEvidenceSealed, true);
});
