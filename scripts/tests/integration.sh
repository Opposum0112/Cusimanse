#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "INTEGRATION FAIL: $*" >&2; exit 1; }
command -v go >/dev/null 2>&1 || fail 'go missing'
for f in scripts/install.sh scripts/preflight.sh scripts/tools.sh scripts/session.sh scripts/run-experiment.sh scripts/policyctl scripts/observability.sh scripts/learningctl; do [ -x "$f" ] || fail "not executable: $f"; done
for f in recipes/host/security-research.yaml recipes/gateway/mandatory.yaml recipes/observability/mandatory.yaml recipes/lima/security-research.yaml recipes/instrumentation/security-research.yaml recipes/session/learning-workflow.yaml docs/HOST-TOOLCHAIN.md docs/INSTRUMENTATION.md prompts/README.md manifest/TOOL-INVENTORY.yaml manifest/PACKAGE-MANIFEST.json; do [ -s "$f" ] || fail "required integration artifact missing: $f"; done
grep -q 'litellm' recipes/gateway/mandatory.yaml || fail 'gateway recipe incomplete'
grep -q 'omniroute' recipes/gateway/mandatory.yaml || fail 'OmniRoute recipe incomplete'
grep -q 'collectors:' recipes/instrumentation/security-research.yaml || fail 'instrumentation recipe incomplete'
grep -q 'default: false' recipes/session/learning-workflow.yaml || fail 'learning must be disabled by default'
grep -q 'human_approval_required: true' recipes/session/learning-workflow.yaml || fail 'learning promotion must require approval'
go test ./... >/dev/null || fail 'Go tests failed'
go run ./cmd/cusimanse validate >/dev/null || fail 'native validation failed'
go run ./cmd/cusimanse preflight >/dev/null || fail 'native preflight failed'
go run ./cmd/cusimanse policy validate >/dev/null || fail 'native policy validation failed'
go run ./cmd/cusimanse policy explain vm >/dev/null || fail 'native policy explain failed'
go run ./cmd/cusimanse policy explain network >/dev/null || fail 'native policy explain failed'
./scripts/tools.sh list >/dev/null
./scripts/tools.sh config >/dev/null
./scripts/tools.sh path >/dev/null
if go run ./cmd/cusimanse policy require host-execution >/dev/null 2>&1; then fail 'denied host execution unexpectedly allowed'; fi
if go run ./cmd/cusimanse policy require vm >/dev/null 2>&1; then fail 'approval-required VM unexpectedly allowed without approval'; fi
go run ./cmd/cusimanse policy require vm --approved >/dev/null || fail 'approved VM action rejected'
for experiment in go-install-001 npm-install-001 npm-lifecycle-001 npm-threat-001; do go run ./cmd/cusimanse resolve "$experiment" >/dev/null || fail "capability resolution failed: $experiment"; test -s "prompts/experiments/$experiment.md" || fail "experiment prompt missing: $experiment"; done
go run ./cmd/cusimanse capability skill list >/dev/null || fail 'skill management unavailable'
go run ./cmd/cusimanse capability role list >/dev/null || fail 'role management unavailable'
./scripts/observability.sh phoenix >/dev/null
./scripts/observability.sh clawmetry >/dev/null
sid="integration-contract-$$"
candidate="integration-learning-$$"
audit="runs/$sid/evidence/audit"
cleanup(){ rm -rf "runs/$sid" "skills/validated/$candidate.yaml"; }
trap cleanup EXIT
./scripts/session.sh create npm-threat-001 adk-cusimanse "$sid" >/dev/null
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
test -s "$sid_dir/evidence/audit/manifest.sha256" || fail 'evidence hash missing'
test -s "$sid_dir/provenance/manifest.sha256" || fail 'provenance hash missing'
mkdir -p "$sid_dir/learning/candidates" "$sid_dir/learning/replays" "$sid_dir/learning/verification"
printf '%s\n' 'version: 1' "id: $candidate" 'scope: integration-test-only' > "$sid_dir/learning/candidate.yaml"
./scripts/learningctl candidate "$sid" "$candidate" "$sid_dir/learning/candidate.yaml" >/dev/null
printf '%s\n' 'version: 1' "candidate: $candidate" > "$sid_dir/learning/replays/replay.yaml"
printf '%s\n' 'version: 1' "candidate: $candidate" > "$sid_dir/learning/verification/verification.yaml"
./scripts/learningctl status "$sid" >/dev/null
./scripts/learningctl promote "$sid" "$candidate" --approved >/dev/null
test -s "skills/validated/$candidate.yaml" || fail 'learning promotion did not produce validated skill'
echo 'INTEGRATION PASS: validation/preflight/policy → host tools → gateways/observability → instrumentation declaration → prompt handoff → roles/skills → capability resolution → session/evidence → gated learning'
if [ "${CUSIMANSE_RUN_VM_TEST:-0}" = 1 ]; then
  command -v limactl >/dev/null 2>&1 || fail 'limactl missing for VM integration'
  name="cusimanse-integration-$$"
  trap 'limactl delete --force "$name" >/dev/null 2>&1 || true; rm -rf "runs/'"$sid"'" "skills/validated/'"$candidate"'.yaml"' EXIT
  limactl validate recipes/lima/security-research.yaml >/dev/null
  limactl start --name="$name" recipes/lima/security-research.yaml >/dev/null
  limactl shell "$name" -- bash -lc 'go version && node --version && npm --version && strace -V >/dev/null && tcpdump --version >/dev/null'
  limactl delete --force "$name" >/dev/null
  echo 'INTEGRATION PASS: disposable Lima/QEMU smoke test'
fi
