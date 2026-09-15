#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "INTEGRATION FAIL: $*" >&2; exit 1; }
command -v go >/dev/null 2>&1 || fail 'go missing'
command -v goose >/dev/null 2>&1 || fail 'goose missing'
for f in scripts/install.sh scripts/preflight.sh scripts/tools.sh scripts/session.sh scripts/run-experiment.sh scripts/policyctl scripts/observability.sh scripts/learningctl; do [ -x "$f" ] || fail "not executable: $f"; done
go test ./... >/dev/null || fail 'Go tests failed'
go run ./cmd/cusimanse validate >/dev/null || fail 'native validation failed'
go run ./cmd/cusimanse preflight >/dev/null || fail 'native preflight failed'
go run ./cmd/cusimanse policy validate >/dev/null || fail 'native policy validation failed'
go run ./cmd/cusimanse policy explain vm >/dev/null || fail 'native policy explain failed'
go run ./cmd/cusimanse policy explain network >/dev/null || fail 'native policy explain failed'
audit="${TMPDIR:-/tmp}/cusimanse-policy-integration-$$.jsonl"
go run ./cmd/cusimanse policy check-all --audit "$audit" >/dev/null || fail 'native policy check-all failed'
./scripts/tools.sh list >/dev/null
./scripts/tools.sh config >/dev/null
./scripts/tools.sh path >/dev/null
if go run ./cmd/cusimanse policy require host-execution >/dev/null 2>&1; then fail 'denied host execution unexpectedly allowed'; fi
if go run ./cmd/cusimanse policy require vm >/dev/null 2>&1; then fail 'approval-required VM unexpectedly allowed without approval'; fi
go run ./cmd/cusimanse policy require vm --approved >/dev/null || fail 'approved VM action rejected'
for recipe in recipes/*/recipe.yaml; do goose recipe validate "$recipe" >/dev/null; done
for recipe in recipes/subrecipes/*.yaml; do goose recipe validate "$recipe" >/dev/null; done
for experiment in go-install-001 npm-install-001 npm-lifecycle-001 npm-threat-001; do go run ./cmd/cusimanse resolve "$experiment" >/dev/null || fail "capability resolution failed: $experiment"; test -s "prompts/experiments/$experiment.md" || fail "experiment prompt missing: $experiment"; done
for operator in opencode hermes antigravity pi; do test -s "prompts/operators/$operator.md" || fail "operator handoff guide missing: $operator"; done
grep -q 'prompt_reference: prompts/experiments/<experiment>.md' recipes/agents/adapter-matrix.yaml || fail 'adapter matrix missing shared prompt reference'
for operator in opencode hermes antigravity pi; do grep -q "adapter_guidance: prompts/operators/$operator.md" recipes/agents/adapter-matrix.yaml || fail "adapter matrix missing $operator guide"; done
grep -q 'prompt_file_required: true' recipes/agents/adapter-matrix.yaml || fail 'prompt file requirement missing'
go run ./cmd/cusimanse capability skill list >/dev/null || fail 'skill management unavailable'
go run ./cmd/cusimanse capability role list >/dev/null || fail 'role management unavailable'
go run ./cmd/cusimanse capability list | grep -q 'skill role' || fail 'capability registry missing role/skill operations'
for generated in experiment-run evidence-analysis forensics report-generation verification; do test -s "recipes/skills/$generated.yaml" || fail "generated skill YAML missing: $generated"; done
for generated in planner researcher runtime-analyst forensics-analyst detection-analyst verifier report-generator; do test -s ".agents/agents/$generated.yaml" || fail "generated role YAML missing: $generated"; done
./scripts/observability.sh phoenix >/dev/null
./scripts/observability.sh clawmetry >/dev/null
./scripts/learningctl --help >/dev/null 2>&1 || true
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
echo 'INTEGRATION PASS: Go validation/preflight/policy → prompt handoff → alternate adapters → Goose recipes → role/skill management → capability resolution → session/evidence hashing'
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