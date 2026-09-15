#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "RUNTIME FAIL: $*" >&2; exit 1; }
command -v go >/dev/null 2>&1 || fail 'go missing'
command -v yq >/dev/null 2>&1 || fail 'yq missing'
yq --version | grep -Eq 'version v4\.' || fail 'yq v4 required'
go test ./... >/dev/null || fail 'Go tests failed'
go run ./cmd/cusimanse validate >/dev/null || fail 'native validation failed'
go run ./cmd/cusimanse policy validate >/dev/null || fail 'native policy validation failed'
sid="runtime-contract-$$"
trap 'rm -rf "runs/$sid"' EXIT
./scripts/session.sh create go-install-001 goose "$sid" >/dev/null
./scripts/session.sh checkpoint "$sid" VALIDATED
./scripts/session.sh checkpoint "$sid" PREFLIGHTED
if ./scripts/session.sh checkpoint "$sid" COMPLETE >/dev/null 2>&1; then fail 'invalid lifecycle transition was accepted'; fi
./scripts/session.sh checkpoint "$sid" PLANNED
./scripts/session.sh checkpoint "$sid" AWAITING_APPROVAL
./scripts/session.sh checkpoint "$sid" APPROVED
./scripts/session.sh checkpoint "$sid" PARTIAL
./scripts/session.sh hash "$sid"
./scripts/session.sh verify-layout "$sid"
test -s "runs/$sid/evidence/audit/manifest.sha256" || fail 'evidence audit manifest missing'
test -s "runs/$sid/provenance/manifest.sha256" || fail 'provenance manifest missing'
grep -q '"state":"PARTIAL"' "runs/$sid/evidence/audit/events.jsonl" || fail 'lifecycle audit event missing'
for exp in go-install-001 npm-install-001 npm-lifecycle-001 npm-threat-001; do go run ./cmd/cusimanse resolve "$exp" >/dev/null || fail "profile resolution failed: $exp"; done
echo 'RUNTIME PASS: Go tests, native validation/policy, profile resolution, lifecycle and evidence hashing'
if [ "${CUSIMANSE_RUN_VM_TEST:-0}" = 1 ]; then
 command -v limactl >/dev/null 2>&1 || fail 'limactl missing for VM test';name="cusimanse-runtime-$$";trap 'limactl delete --force "$name" >/dev/null 2>&1 || true; rm -rf "runs/$sid"' EXIT;limactl validate recipes/lima/security-research.yaml;limactl start --name="$name" recipes/lima/security-research.yaml;limactl shell "$name" -- bash -lc 'go version && node --version && npm --version && strace -V && tcpdump --version >/dev/null';limactl delete --force "$name";echo 'RUNTIME PASS: Lima disposable VM smoke test'
fi
