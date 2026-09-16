import assert from "node:assert/strict";
import test from "node:test";
import { evaluateContractIntent, isEvidenceSealed } from "../../src/contract/index.js";
import type { CusimanseIR } from "../../src/ir/index.js";
import { createResearchState } from "../../src/state/index.js";

function ir(overrides: Partial<CusimanseIR["contract"]> = {}): CusimanseIR {
  return {
    version: "v1",
    experimentId: "contract-test",
    source: { format: "json", path: "tests/contract/contract.test.ts" },
    intents: [],
    contract: {
      contractVersion: "0.2",
      allowedCapabilities: ["network.observe", "vm.destroy"],
      operationKinds: ["network", "vm"],
      evidenceRequired: [{ type: "network" }],
      stopWhen: { allEvidenceRequired: true, maxProposals: 2 },
      destroy: { capability: "vm.destroy", requireEvidenceSealed: true },
      ...overrides,
    },
  };
}

test("allowlist rejects capabilities the contract did not name", () => {
  const decision = evaluateContractIntent(
    ir(),
    { id: "x", capability: "host.shell", parameters: {}, dependsOn: [] },
    createResearchState("contract-test"),
  );
  assert.equal(decision.allowed, false);
  assert.equal(decision.code, "not_in_contract_allowlist");
});

test("destroy is blocked until required evidence exists", () => {
  const empty = createResearchState("contract-test");
  const blocked = evaluateContractIntent(
    ir(),
    { id: "d", capability: "vm.destroy", parameters: {}, dependsOn: [] },
    empty,
  );
  assert.equal(blocked.allowed, false);
  assert.equal(blocked.code, "destroy_blocked_until_evidence");

  const sealed = createResearchState("contract-test");
  sealed.evidence.push({ id: "ev-1", kind: "network", uri: "evidence://pcap" });
  const allowed = evaluateContractIntent(
    ir(),
    { id: "d", capability: "vm.destroy", parameters: {}, dependsOn: [] },
    sealed,
  );
  assert.equal(allowed.allowed, true);
  assert.equal(isEvidenceSealed(ir(), sealed), true);
});

test("working_directory outside scope.paths is a scope violation", () => {
  const decision = evaluateContractIntent(
    ir({
      scope: { hosts: ["disposable-vm"], paths: ["/workspace"], networks: [] },
      allowedCapabilities: ["workload.npm.install"],
    }),
    { id: "i", capability: "workload.npm.install", parameters: { working_directory: "/etc" }, dependsOn: [] },
    createResearchState("contract-test"),
  );
  assert.equal(decision.allowed, false);
  assert.equal(decision.code, "scope_violation");
});
