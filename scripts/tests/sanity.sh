#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "SANITY FAIL: $*" >&2; exit 1; }
command -v go >/dev/null 2>&1 || fail 'Go is required'
command -v yq >/dev/null 2>&1 || fail 'yq is required'

yq -e '.kind == "capability-registry" and .resolver == "cmd/cusimanse" and .rules.deterministic == true and .rules.fail_on_no_match == true and .rules.fail_on_ambiguous_match == true and .rules.agent_may_create_profiles == false' recipes/profiles/registry.yaml >/dev/null || fail 'invalid capability registry'

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

# Goose sub_recipes provide Summon automatically. If a recipe has an explicit
# extensions block and uses delegate/load, require an explicit summon entry.
for recipe in recipes/*/recipe.yaml; do
  if grep -Eq '\b(delegate|load)\s*\(' "$recipe" && yq -e '.extensions' "$recipe" >/dev/null 2>&1; then
    yq -e '.extensions[] | select(.name == "summon")' "$recipe" >/dev/null || fail "$recipe uses delegate/load with explicit extensions but omits summon"
  fi
done

for contract in contracts/*.md; do
  id="$(basename "$contract" .md)"
  exp="recipes/experiments/$id.yaml"
  [ -s "$exp" ] || continue
  checks="$(yq -r '.policy.required_checks[]' "$exp" | sort | tr '\n' ' ')"
  for required in vm network mounts; do
    echo "$checks" | grep -qw "$required" || fail "$exp missing required policy check: $required"
  done
done

yq -e '.common.commands and .platforms and .guest and .mandatory_services' recipes/host/security-research.yaml >/dev/null || fail 'host inventory schema incomplete'
yq -e '.gateways and .observability and .research_reporting' recipes/observability/mandatory.yaml >/dev/null || fail 'observability inventory schema incomplete'
yq -e '.omniroute and .litellm' recipes/gateway/mandatory.yaml >/dev/null || fail 'gateway inventory schema incomplete'

go test ./cmd/cusimanse
printf '%s\n' 'SANITY PASS: runtime compiles/tests, experiments map to contracts/profiles/policy, Goose summon semantics are checked correctly, and inventories are schema-checked without treating inventory as runtime readiness.'
