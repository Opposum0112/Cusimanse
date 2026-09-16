import { createLab } from "../lab/index.js";
import type { Adapter } from "../adapters/index.js";
import type { PolicyRule } from "../policy/index.js";
import { parseStraceRequest, parseSysdigRequest } from "../adapters/instrumentation.js";

const contract = {
  api_version: "v1",
  kind: "ExperimentRecipe",
  experiment_id: "npm-install-day0",
  contract_version: "0.2",
  research_question: {
    id: "rq-npm-install",
    question: "What observable process, filesystem, and network behavior occurs during npm install?",
    non_goals: [
      "Do not exploit the package or the registry.",
      "Do not persist the VM after evidence is sealed.",
    ],
  },
  scope: { paths: ["/workspace"], hosts: ["disposable-vm"], networks: ["declared-test-network"] },
  allowed_capabilities: [
    "vm.create",
    "vm.destroy",
    "workload.npm.install",
    "evidence.collect",
    "network.observe",
    "instrumentation.strace",
    "instrumentation.sysdig",
  ],
  operation_kinds: ["vm", "tool", "evidence", "network"],
  intents: [
    { id: "provision-research-vm", capability: "vm.create", parameters: { provider: "lima" }, depends_on: [] },
  ],
  evidence_required: [
    { type: "process", produced_by: "evidence.collect" },
    { type: "network", produced_by: "network.observe" },
    { type: "log", produced_by: "workload.npm.install" },
  ],
  stop_when: { all_evidence_required: true, max_proposals: 20 },
  destroy: { capability: "vm.destroy", require_evidence_sealed: true },
};

const policy: PolicyRule[] = [
  { id: "allow-vm-create", capability: "vm.create", decision: "allow", reason: "Disposable VM." },
  { id: "allow-vm-destroy", capability: "vm.destroy", decision: "allow", reason: "Destroy after seal." },
  { id: "allow-install", capability: "workload.npm.install", decision: "allow", reason: "Declared workload." },
  { id: "allow-observe", capability: "network.observe", decision: "allow", reason: "In contract." },
  { id: "allow-evidence", capability: "evidence.collect", decision: "allow", reason: "Required evidence." },
  { id: "allow-strace", capability: "instrumentation.strace", decision: "allow", reason: "Allowlisted strace." },
  { id: "allow-sysdig", capability: "instrumentation.sysdig", decision: "allow", reason: "Allowlisted sysdig." },
];

const capabilityNames = [
  "vm.create",
  "vm.destroy",
  "workload.npm.install",
  "network.observe",
  "evidence.collect",
  "instrumentation.strace",
  "instrumentation.sysdig",
];

const capabilities = capabilityNames.map((name) => ({
  name,
  version: "v1",
  operationKinds: name.startsWith("vm.") ? ["vm"] : name.startsWith("instrumentation.") ? ["tool"] : name === "network.observe" ? ["network"] : ["evidence"],
}));

const adapters: Adapter[] = [
  {
    name: "lab-stubs",
    capabilities: capabilityNames,
    async execute(context, parameters) {
      if (context.operationId && parameters && "target" in parameters) parseStraceRequest(parameters);
      if (parameters && parameters["profile"]) parseSysdigRequest(parameters);
      return {
        status: "succeeded",
        evidenceRefs: [`evidence://npm-install-day0/${context.operationId}`],
      };
    },
  },
];

const port = Number(process.env.CUSIMANSE_PORT ?? 8787);

createLab({
  contract,
  contractPath: "labs/npm-install-day0/contract.yaml",
  policy,
  capabilities,
  adapters,
  gateway: true,
  listen: { host: "127.0.0.1", port },
});

console.log(`npm-install-day0 lab is listening on http://127.0.0.1:${port}`);
console.log("This host checks contracts and instrumentation parameters. It does not boot Lima or exec strace/sysdig.");
