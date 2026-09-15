#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "INTEGRATION FAIL: $*" >&2; exit 1; }
command -v go >/dev/null 2>&1 || fail 'go missing'
command -v goose >/dev/null 2>&1 || fail 'goose missing'
command -v yq >/dev/null 2>&1 || fail 'yq missing'
for f in scripts/install.sh scripts/preflight.sh scripts/tools.sh scripts/session.sh scripts/run-experiment.sh scripts/policyctl scripts/observability.sh scripts/learningctl; do [ -x "$f" ] || fail "not executable: $f"; done
./scripts/policyctl validate >/dev/null
./scripts/policyctl explain vm >/dev/null
./scripts/policyctl explain network >/dev/null
./scripts/policyctl check-all --audit "${TMPDIR:-/tmp}/cusimanse-policy-integration-$$.jsonl" >/dev/null
./scripts/tools.sh list >/dev/null
./scripts/tools.sh config >/dev/null
./scripts/tools.sh path >/dev/null
for action in credentials mounts vm network git-write; do ./scripts/policyctl check "$action" --audit "${TMPDIR:-/tmp}/cusimanse-policy-integration-$$.jsonl" >/dev/null; done
if ./scripts/policyctl require host-execution >/dev/null 2>&1; then fail 'denied host execution unexpectedly allowed'; fi
if ./scripts/policyctl require vm >/dev/null 2>&1; then fail 'approval-required VM unexpectedly allowed without approval'; fi
./scripts/policyctl require vm --approved >/dev/null || fail 'approved VM action rejected'
yq -e '.common.commands | length > 0' recipes/host/security-research.yaml >/dev/null || fail 'common host inventory missing'
yq -e '.guest.commands | length > 0' recipes/host/security-research.yaml >/dev/null || fail 'guest inventory missing'
yq -e '.components.omniroute.bind == "127.0.0.1:20128" and .components.litellm.bind == "127.0.0.1:4000"' recipes/gateway/mandatory.yaml >/dev/null || fail 'gateway localhost configuration mismatch'
yq -e '.components.numbat and .components.aegis and .components.phoenix and .components.opentelemetry and .components.clawmetry' recipes/observability/mandatory.yaml >/dev/null || fail 'observability inventory incomplete'
yq -e '.research_reporting.role == "report-generator" and (.correlation.required_fields | length) >= 8' recipes/observability/mandatory.yaml >/dev/null || fail 'report/correlation observability contract incomplete'
yq -e '.reference.agent == "goose" and .reference.mode == "native-recipe" and (.adapters | keys | length) == 4' recipes/agents/adapter-matrix.yaml >/dev/null || fail 'agent adapter matrix incomplete'
yq -e '.reference.operator_sequence | length >= 6' recipes/agents/adapter-matrix.yaml >/dev/null || fail 'operator sequence missing'
yq -e '.adapter_contract.recipe_mutation == "forbidden" and .adapter_contract.execution_boundary == "Lima/QEMU + guest OS"' recipes/agents/adapter-matrix.yaml >/dev/null || fail 'adapter contract boundary incomplete'
yq -e '.skills | length > 0 and .roles | length > 0' recipes/agents/role-skill-registry.json >/dev/null || fail 'Go role/skill registry empty'
yq -e '.source == "recipes/agents/role-skill-registry.json"' recipes/agents/role-skill-bindings.yaml >/dev/null || fail 'generated role/skill bindings missing'
for prompt in prompts/experiments/*.md; do grep -q 'Read first:' "$prompt" || fail "prompt missing read-first contract: $prompt"; done
for recipe in recipes/*/recipe.yaml; do goose recipe validate "$recipe" >/dev/null; done
for recipe in recipes/subrecipes/*.yaml; do goose recipe validate "$recipe" >/dev/null; done
for experiment in go-install-001 npm-install-001 npm-lifecycle-001 npm-threat-001; do go run ./cmd/cusimanse resolve "$experiment" >/dev/null || fail "capability resolution failed: $experiment"; done
go run ./cmd/cusimanse capability skill list >/dev/null || fail 'skill management unavailable'
go run ./cmd/cusimanse capability role list >/dev/null || fail 'role management unavailable'
go run ./cmd/cusimanse capability list | grep -q 'skill role' || fail 'capability registry missing role/skill operations'
for generated in experiment-run evidence-analysis forensics report-generation verification; do test -s "recipes/skills/$generated.yaml" || fail "generated skill YAML missing: $generated"; done
for generated in planner researcher runtime-analyst forensics-analyst detection-analyst verifier report-generator; do test -s ".agents/agents/$generated.yaml" || fail "generated role YAML missing: $generated"; done
yq -e '.enabled.default == false and .promotion_rules.human_approval_required == true and .commands.promote | contains("--approved")' recipes/session/learning-workflow.yaml >/dev/null || fail 'learning contract incomplete'
./scripts/observability.sh phoenix >/dev/null
./scripts/observability.sh clawmetry >/dev/null
./scripts/learningctl --help >/dev/null 2>&1 || true

audit="${TMPDIR:-/tmp}/cusimanse-policy-integration-$$.jsonl"
sid="integration-contract-$$"
cleanup(){ rm -rf "runs/$sid" "$audit"; }
trap cleanup EXIT
./scripts/session.sh create npm-threat-001 goose "$sid" >/dev/null
./scripts/session.sh checkpoint "$sid" VALIDATED >/dev/null
./scripts/session.sh checkpoint "$sid" PREFLIGHTED >/dev/null
./scripts/session.sh checkpoint "$sid" PLANNED >/dev/null
./scripts/session.sh checkpoint "$sid" AWAITING_APPROVAL >/dev/null
./scripts/session.sh checkpoint "$sid" APPROVED >/dev/null
./scripts/session.sh checkpoint "$sid" PARTIAL >/dev/null
sid_dir="runs/$sid"
printf '%s\n' 'version: 1' 'session_id: '"$sid" > "$sid_dir/evidence/index.yaml"
printf '%s\n' '# Integration analysis placeholder' > "$sid_dir/analysis/summary.md"
printf '%s\n' '# Integration verification placeholder' > "$sid_dir/verification/result.md"
printf '%s\n' '# Integration report placeholder' > "$sid_dir/research-report/report.md"
printf '%s\n' 'version: 1' 'session_id: '"$sid" > "$sid_dir/research-report/report.yaml"
./scripts/session.sh hash "$sid" >/dev/null
./scripts/session.sh verify-layout "$sid" >/dev/null
test -s "$sid_dir/session.yaml" || fail 'session missing'
test -s "$sid_dir/evidence/audit/events.jsonl" || fail 'audit events missing'
test -s "$sid_dir/evidence/audit/manifest.sha256" || fail 'evidence hash missing'
test -s "$sid_dir/provenance/manifest.sha256" || fail 'provenance hash missing'
echo 'INTEGRATION PASS: inventory → gateways/observability → policy decisions → adapters/prompts → Goose recipes → role/skill management → learning contract → capability resolution → session/evidence hashing'
if [ "${CUSIMANSE_RUN_VM_TEST:-0}" = 1 ]; then
  command -v limactl >/dev/null 2>&1 || fail 'limactl missing for VM integration'
  name="cusimanse-integration-$$"
  trap 'limactl delete --force "$name" >/dev/null 2>&1 || true; rm -rf "runs/'"$sid"'" "$audit"' EXIT
  limactl validate recipes/lima/security-research.yaml >/dev/null
  limactl start --name="$name" recipes/lima/security-research.yaml >/dev/null
  limactl shell "$name" -- bash -lc 'go version && node --version && npm --version && strace -V >/dev/null && tcpdump --version >/dev/null'
  limactl delete --force "$name" >/dev/null
  echo 'INTEGRATION PASS: disposable Lima/QEMU smoke test'
fi
