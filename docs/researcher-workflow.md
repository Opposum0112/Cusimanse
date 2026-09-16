# Researcher workflow

One experiment = one lab folder. Example: [`labs/npm-install-day0/`](../labs/npm-install-day0/).

## Files to create

```text
labs/<experiment-id>/
  contract.yaml          # required
  policy.yaml            # required (host maps rules into PolicyEngine)
  fixtures/              # pinned subject under test
  README.md              # this lab only
```

### contract.yaml

Question, `non_goals`, `scope`, `allowed_capabilities`, planned `intents`, `evidence_required`, `stop_when`, `destroy`.
See [research-contracts.md](research-contracts.md) and [recipe-authoring.md](recipe-authoring.md).

### policy.yaml

Default deny. One rule per capability you intend to allow. Policy is not approval the model can grant.

### fixtures

For npm-install-day0, `fixtures/package.json` pins `left-pad@1.3.0`. The operator does not run `npm` itself; `workload.npm.install` does, inside scope.

## Files not to create

- `run.sh` / shell the model will invoke
- credentials in YAML
- extra tools besides the proposal HTTP client
- a mutated contract mid-run (new question → new `experiment_id`)

## Drive the lab

1. `createLab({ contract, policy, capabilities, adapters, gateway: true })`
2. Operator (any harness) GET state.
3. Propose only allowlisted capabilities that match a skill/role.
4. GET evidence.
5. `complete: true` or sealed `vm.destroy`.

npm-install-day0 expected proposals:

1. `workload.npm.install` `{ working_directory: "/workspace", package_manager: "npm" }`
2. `network.observe`
3. `evidence.collect`
4. stop

`host.shell` must deny with `not_in_contract_allowlist`.
