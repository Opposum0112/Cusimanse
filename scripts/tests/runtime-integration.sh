#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE="${CUSIMANSE_LIMA_PROFILE:-$ROOT/recipes/lima/profiles/security-research.yaml}"
VM="${CUSIMANSE_TEST_VM:-cusimanse-runtime-smoke}"
RUN_ID="${CUSIMANSE_RUN_ID:-runtime-smoke-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$ROOT/reports/runtime/$RUN_ID"
EVIDENCE="$RUN_DIR/evidence"
TELEMETRY="$RUN_DIR/telemetry"
PROVENANCE="$RUN_DIR/provenance"
ANALYSIS="$RUN_DIR/analysis"
VERIFICATION="$RUN_DIR/verification"
REPORT="$RUN_DIR/research-report"
mkdir -p "$EVIDENCE" "$TELEMETRY" "$PROVENANCE" "$ANALYSIS" "$VERIFICATION" "$REPORT"
command -v limactl >/dev/null || { echo 'RUNTIME TEST SKIP: limactl unavailable'; exit 2; }
[ -f "$PROFILE" ] || { echo "RUNTIME TEST FAIL: missing Lima profile $PROFILE"; exit 1; }
cleanup(){ limactl delete "$VM" --force >/dev/null 2>&1 || true; }
trap cleanup EXIT
cat > "$RUN_DIR/run.yaml" <<EOF
version: 1
id: $RUN_ID
kind: runtime-smoke
profile: $PROFILE
vm: $VM
workload: /tmp/cusimanse-runtime/workload.txt
instrumentation: VM-side smoke capture
acceptance: disposable VM execution, preserved evidence, hash verification, smoke analysis and report
EOF
limactl start --name "$VM" "$PROFILE"
limactl shell "$VM" -- bash -lc 'uname -a; command -v go >/dev/null; mkdir -p /tmp/cusimanse-runtime'
limactl shell "$VM" -- bash -lc 'cd /tmp/cusimanse-runtime && printf "runtime-smoke\n" > workload.txt && sha256sum workload.txt'
limactl shell "$VM" -- bash -lc 'cd /tmp/cusimanse-runtime && cat workload.txt' > "$EVIDENCE/workload.stdout"
limactl shell "$VM" -- bash -lc 'cd /tmp/cusimanse-runtime && uname -a' > "$TELEMETRY/uname.txt"
(
  cd "$RUN_DIR"
  sha256sum evidence/workload.stdout telemetry/uname.txt > provenance/hashes.sha256
)
cat > "$ANALYSIS/summary.md" <<EOF
# Runtime smoke analysis

The declared smoke workload executed inside the disposable Lima/QEMU VM. The preserved workload output and VM metadata are the evidence for this smoke acceptance test.

This is a runtime integration check, not a security finding and not proof that every adapter, instrumentation backend, or isolation control is production-ready.
EOF
cat > "$VERIFICATION/result.md" <<EOF
# Independent smoke verification

Verification checks:

- workload evidence exists;
- VM telemetry exists;
- SHA-256 provenance manifest was generated;
- VM deletion is registered by the EXIT cleanup handler.

Result: PASS for the repository runtime smoke contract.
EOF
cat > "$REPORT/report.md" <<EOF
# Runtime integration report

Run: $RUN_ID

Result: PASS for disposable-VM smoke execution.

Artifacts: evidence/workload.stdout, telemetry/uname.txt, provenance/hashes.sha256, analysis/summary.md, verification/result.md.

Scope limitation: this smoke test does not validate every primary-agent adapter or every optional instrumentation/observability integration.
EOF
printf 'RUNTIME PASS: disposable VM workload executed; run=%s; evidence=%s\n' "$RUN_ID" "$RUN_DIR"
