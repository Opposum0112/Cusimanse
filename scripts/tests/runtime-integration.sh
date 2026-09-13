#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
fail(){ printf 'RUNTIME INTEGRATION FAIL: %s\n' "$*" >&2; exit 1; }
pass(){ printf 'RUNTIME INTEGRATION PASS: %s\n' "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }
VM="${CUSIMANSE_TEST_VM:-cusimanse-runtime-smoke}"
PROFILE="${CUSIMANSE_LIMA_PROFILE:-}"
[ -n "$PROFILE" ] || fail 'set CUSIMANSE_LIMA_PROFILE to a reviewed Lima YAML profile'
have limactl || fail 'limactl is required'
[ -f "$PROFILE" ] || fail "Lima profile not found: $PROFILE"
cleanup(){ limactl stop "$VM" >/dev/null 2>&1 || true; limactl delete "$VM" >/dev/null 2>&1 || true; }
trap cleanup EXIT
limactl delete "$VM" >/dev/null 2>&1 || true
limactl start --name "$VM" "$PROFILE"
limactl shell "$VM" -- bash -lc 'set -e; command -v bash; uname -a; mkdir -p /tmp/cusimanse-runtime-smoke; printf "runtime-smoke\n" > /tmp/cusimanse-runtime-smoke/workload.txt; sha256sum /tmp/cusimanse-runtime-smoke/workload.txt'
mkdir -p "evidence/runs/${VM}/runtime-smoke" "blackboard/runs/${VM}/provenance"
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-runtime-smoke/workload.txt' > "evidence/runs/${VM}/runtime-smoke/workload.txt"
sha256sum "evidence/runs/${VM}/runtime-smoke/workload.txt" > "blackboard/runs/${VM}/provenance/hashes.sha256"
[ -s "blackboard/runs/${VM}/provenance/hashes.sha256" ] || fail 'evidence hash was not preserved'
pass "disposable Lima VM created, workload executed inside VM, evidence collected and hashed"
if limactl shell "$VM" -- bash -lc 'command -v npm >/dev/null 2>&1'; then
  limactl shell "$VM" -- bash -lc 'cd /tmp/cusimanse-runtime-smoke && npm --version && printf "{\"scripts\":{\"test\":\"node -e '\''console.log(\"npm-runtime-pass\")'\''\"}}\n" > package.json && npm test' | tee "evidence/runs/${VM}/runtime-smoke/npm.log"
  pass "npm workload smoke test completed inside VM"
else
  printf '%s\n' 'npm not deployed in selected VM; npm workload integration remains NOT_DEPLOYED.' | tee "evidence/runs/${VM}/runtime-smoke/npm-status.txt"
fi
printf '%s\n' 'Runtime smoke test intentionally destroys the disposable VM on exit.'
