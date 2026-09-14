#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
usage(){ echo "usage: $0 <go-install-001|npm-install-001|npm-lifecycle-001> [session-id]"; exit 2; }
[ $# -ge 1 ] || usage
EXP="$1"; SESSION="${2:-$(date -u +%Y%m%dT%H%M%SZ)-$1}"
case "$EXP" in
  go-install-001|npm-install-001|npm-lifecycle-001) CONFIG="recipes/experiments/$EXP.yaml";;
  *) echo "RUNTIME FAIL: unknown experiment $EXP" >&2; exit 2;;
esac
command -v yq >/dev/null || { echo 'RUNTIME FAIL: yq missing'; exit 1; }
command -v limactl >/dev/null || { echo 'RUNTIME FAIL: limactl missing'; exit 1; }
[ -s "$CONFIG" ] || { echo "RUNTIME FAIL: missing $CONFIG"; exit 1; }
RUN="runs/$SESSION"
./scripts/session.sh create "$EXP" "${CUSIMANSE_PRIMARY_AGENT:-goose}" "$SESSION" >/dev/null
printf '%s\n' "experiment: $EXP" "configuration: $CONFIG" "instrumentation: recipes/instrumentation/security-research.yaml" > "$RUN/evidence/index.yaml"
./scripts/session.sh checkpoint "$SESSION" VALIDATED
limactl validate recipes/lima/security-research.yaml
VM="cusimanse-$SESSION"
cleanup(){ limactl delete --force "$VM" >/dev/null 2>&1 || true; }
trap cleanup EXIT
./scripts/session.sh checkpoint "$SESSION" PROVISIONED
limactl start --name="$VM" recipes/lima/security-research.yaml
./scripts/session.sh checkpoint "$SESSION" INSTRUMENTED
limactl shell "$VM" -- bash -lc 'date -u +%Y-%m-%dT%H:%M:%SZ; ps -ef; ss -tunap' > "$RUN/evidence/pre-workload.txt" 2>&1 || true
# Copy only the approved local fixture/source into the VM; no host mounts are used.
if [ "$EXP" = go-install-001 ]; then
  tar -C packages -cf - labprobe | limactl shell "$VM" -- bash -lc 'mkdir -p /workspace/packages && tar -xf - -C /workspace/packages'
elif [ "$EXP" = npm-lifecycle-001 ]; then
  tar -C packages -cf - npm-fixture | limactl shell "$VM" -- bash -lc 'mkdir -p /workspace/packages && tar -xf - -C /workspace/packages'
fi
./scripts/session.sh checkpoint "$SESSION" EXECUTING
case "$EXP" in
  go-install-001)
    limactl shell "$VM" -- bash -lc 'set -e; cd /workspace/packages/labprobe; strace -ff -o /tmp/cusimanse-strace go install .; command -v labprobe; labprobe' > "$RUN/evidence/workload.txt" 2>&1
    ;;
  npm-install-001)
    limactl shell "$VM" -- bash -lc 'set -e; node --version; npm --version; mkdir -p /tmp/npm-test; cd /tmp/npm-test; npm init -y; strace -ff -o /tmp/cusimanse-strace npm install lodash@4.17.21 --ignore-scripts' > "$RUN/evidence/workload.txt" 2>&1
    ;;
  npm-lifecycle-001)
    limactl shell "$VM" -- bash -lc 'set -e; node --version; npm --version; mkdir -p /tmp/npm-lifecycle; cd /tmp/npm-lifecycle; npm init -y; strace -ff -o /tmp/cusimanse-strace npm install /workspace/packages/npm-fixture; test -f /tmp/cusimanse-npm-lifecycle-marker' > "$RUN/evidence/workload.txt" 2>&1
    ;;
esac
limactl shell "$VM" -- bash -lc 'cp /tmp/cusimanse-strace* /tmp/cusimanse-evidence 2>/dev/null || true; ps -ef; ss -tunap; find /tmp -maxdepth 2 -type f -name "cusimanse-*" -print 2>/dev/null | sort' > "$RUN/evidence/post-workload.txt" 2>&1 || true
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-strace* 2>/dev/null' > "$RUN/evidence/syscalls.txt" 2>/dev/null || true
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-npm-lifecycle-marker 2>/dev/null' > "$RUN/evidence/lifecycle-marker.txt" 2>/dev/null || true
./scripts/session.sh checkpoint "$SESSION" EVIDENCE_COLLECTED
./scripts/session.sh hash "$SESSION"
./scripts/session.sh checkpoint "$SESSION" ANALYZING
cat > "$RUN/analysis/summary.md" <<EOF
# Analysis

Experiment: $EXP

Runtime evidence was collected from the disposable Lima VM. The selected primary agent must replace this provisional summary with cited observations and inference analysis.
EOF
./scripts/session.sh checkpoint "$SESSION" VERIFYING
cat > "$RUN/verification/result.md" <<'EOF'
# Verification

Status: PENDING_INDEPENDENT_REVIEW

The primary agent must perform independent verification before marking the session complete.
EOF
./scripts/session.sh checkpoint "$SESSION" REPORTED
cat > "$RUN/research-report/report.md" <<EOF
# Cusimanse Research Report

Experiment: $EXP
Session: $SESSION

Status: PENDING_INDEPENDENT_REVIEW

Evidence is preserved under `evidence/`. This provisional report must not be treated as a final research conclusion until independent verification is recorded.
EOF
cat > "$RUN/research-report/report.yaml" <<EOF
experiment: $EXP
session_id: $SESSION
verification: PENDING_INDEPENDENT_REVIEW
evidence: evidence/
EOF
./scripts/session.sh checkpoint "$SESSION" PRESERVED
./scripts/session.sh hash "$SESSION"
./scripts/session.sh verify-layout "$SESSION" || true
./scripts/session.sh checkpoint "$SESSION" DESTROYED
printf 'RUNTIME PARTIAL: disposable VM execution and evidence capture completed; independent verification and final report completion remain required. Session: %s\n' "$RUN"
