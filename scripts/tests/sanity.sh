#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "SANITY FAIL: $*" >&2; exit 1; }
command -v go >/dev/null 2>&1 || fail 'Go is required'
command -v yq >/dev/null 2>&1 || fail 'yq is required'

# Validate the capability registry as data, not merely by file existence.
yq -e '.kind == "capability-registry" and .resolver == "cmd/cusimanse" and .rules.deterministic == true and .rules.fail_on_no_match == true and .rules.fail_on_ambiguous_match == true and .rules.agent_may_create_profiles == false' recipes/profiles/registry.yaml >/dev/null || fail 'invalid capability registry'

# Every experiment must reference an existing contract and registered profile-compatible workload.
for exp in recipes/experiments/*.yaml; do
  contract="$(yq -r '.contract' "$exp")"
  [ -s "$contract" ] || fail "$exp references missing contract: $contract"
  workload="$(yq -r '.requirements.workload' "$exp")"
  found=0
  while IFS= read -r profile; do
    [ -n "$profile" ] || continue
    if [ "$(yq -r '.id' "$profile")" = "$workload" ]; then found=1; break; fi
  done < <(yq -r '.workloads[]' recipes/profiles/registry.yaml)
  [ "$found" -eq 1 ] || fail "$exp workload is not registered: $workload"
  yq -e '.requirements.execution == "disposable" and .requirements.os == "linux" and (.requirements.instrumentation | length > 0)' "$exp" >/dev/null || fail "$exp has incomplete execution requirements"
done

# Goose recipes must explicitly declare summon when they use subagents/delegation.
for recipe in recipes/*/recipe.yaml; do
  if grep -Eq '\b(delegate|load)\s*\(' "$recipe" || yq -e '.sub_recipes | length > 0' "$recipe" >/dev/null 2>&1; then
    yq -e '.extensions[] | select(.name == "summon")' "$recipe" >/dev/null || fail "$recipe uses delegation/subrecipes but does not explicitly enable summon"
  fi
done

# Contracts and experiments must agree on the required policy actions.
for contract in contracts/*.md; do
  id="$(basename "$contract" .md)"
  exp="recipes/experiments/$id.yaml"
  [ -s "$exp" ] || continue
  checks="$(yq -r '.policy.required_checks[]' "$exp" | sort | tr '\n' ' ')"
  for required in vm network mounts; do
    echo "$checks" | grep -qw "$required" || fail "$exp missing required policy check: $required"
  done
done

# Static inventory is not runtime readiness. Record both concepts separately.
yq -e '.common.commands and .platforms and .guest and .mandatory_services' recipes/host/security-research.yaml >/dev/null || fail 'host inventory schema incomplete'
yq -e '.gateways and .observability and .research_reporting' recipes/observability/mandatory.yaml >/dev/null || fail 'observability inventory schema incomplete'
yq -e '.omniroute and .litellm' recipes/gateway/mandatory.yaml >/dev/null || fail 'gateway inventory schema incomplete'

go test ./cmd/cusimanse
printf '%s\n' 'SANITY PASS: runtime compiles/tests, experiments map to contracts/profiles/policy, Goose summon is explicit, and inventories are schema-checked without treating inventory as runtime readiness.'
