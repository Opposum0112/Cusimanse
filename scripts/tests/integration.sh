#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

fail(){ echo "INTEGRATION FAIL: $*" >&2; exit 1; }
command -v goose >/dev/null 2>&1 || fail 'goose missing'
command -v yq >/dev/null 2>&1 || fail 'yq missing'
[ -x scripts/policyctl ] || fail 'policyctl not executable'

./scripts/policyctl validate >/dev/null
for action in credentials mounts vm network git-write; do
  ./scripts/policyctl check "$action" --audit "${TMPDIR:-/tmp}/cusimanse-policy-integration-$$.jsonl" >/dev/null
done

for recipe in recipes/*/recipe.yaml; do goose recipe validate "$recipe" >/dev/null; done

sid="integration-contract-$$"
trap 'rm -rf "runs/$sid" "${TMPDIR:-/tmp}/cusimanse-policy-integration-$$.jsonl"' EXIT
./scripts/session.sh create npm-threat-001 goose "$sid" >/dev/null
./scripts/session.sh checkpoint "$sid" VALIDATED >/dev/null
./scripts/session.sh checkpoint "$sid" PREFLIGHTED >/dev/null
./scripts/session.sh checkpoint "$sid" PLANNED >/dev/null
./scripts/session.sh checkpoint "$sid" AWAITING_APPROVAL >/dev/null
./scripts/session.sh checkpoint "$sid" APPROVED >/dev/null
./scripts/session.sh checkpoint "$sid" PARTIAL >/dev/null
./scripts/session.sh verify-layout "$sid" >/dev/null
./scripts/session.sh hash "$sid" >/dev/null

test -s "runs/$sid/session.yaml" || fail 'session missing'
test -s "runs/$sid/evidence/audit/events.jsonl" || fail 'audit events missing'
test -s "runs/$sid/evidence/audit/manifest.sha256" || fail 'evidence hash missing'
test -s "runs/$sid/provenance/manifest.sha256" || fail 'provenance hash missing'

echo 'INTEGRATION PASS: policyctl → Goose recipe → session lifecycle → evidence hashing'

if [ "${CUSIMANSE_RUN_VM_TEST:-0}" = 1 ]; then
  command -v limactl >/dev/null 2>&1 || fail 'limactl missing for VM integration'
  name="cusimanse-integration-$$"
  trap 'limactl delete --force "$name" >/dev/null 2>&1 || true; rm -rf "runs/$sid" "${TMPDIR:-/tmp}/cusimanse-policy-integration-$$.jsonl"' EXIT
  limactl validate recipes/lima/security-research.yaml >/dev/null
  limactl start --name="$name" recipes/lima/security-research.yaml >/dev/null
  limactl shell "$name" -- bash -lc 'go version && node --version && npm --version && strace -V >/dev/null'
  limactl delete --force "$name" >/dev/null
  echo 'INTEGRATION PASS: disposable Lima/QEMU smoke test'
fi
