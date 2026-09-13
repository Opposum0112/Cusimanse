#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE="${CUSIMANSE_LIMA_PROFILE:-$ROOT/experiments/go-install-001/lima.yaml}"
VM="${CUSIMANSE_TEST_VM:-cusimanse-runtime-smoke}"
EVIDENCE="$ROOT/reports/runtime/$VM"
mkdir -p "$EVIDENCE"
command -v limactl >/dev/null || { echo 'RUNTIME TEST SKIP: limactl unavailable'; exit 2; }
[ -f "$PROFILE" ] || { echo "RUNTIME TEST FAIL: missing Lima profile $PROFILE"; exit 1; }
cleanup(){ limactl delete "$VM" --force >/dev/null 2>&1 || true; }
trap cleanup EXIT
limactl start --name "$VM" "$PROFILE"
limactl shell "$VM" -- bash -lc 'uname -a; command -v go >/dev/null; mkdir -p /tmp/cusimanse-runtime'
limactl shell "$VM" -- bash -lc 'cd /tmp/cusimanse-runtime && printf "runtime-smoke\n" > workload.txt && sha256sum workload.txt'
limactl shell "$VM" -- bash -lc 'cd /tmp/cusimanse-runtime && cat workload.txt' > "$EVIDENCE/workload.stdout"
sha256sum "$EVIDENCE/workload.stdout" > "$EVIDENCE/hashes.sha256"
printf 'RUNTIME PASS: disposable VM workload executed and evidence preserved at %s\n' "$EVIDENCE"
