#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
usage() { echo "usage: $0 <go-install-001|npm-install-001> [session-id]"; exit 2; }
[ $# -ge 1 ] || usage
EXP="$1"; SESSION="${2:-$(date -u +%Y%m%dT%H%M%SZ)-$1}"
case "$EXP" in
  go-install-001|npm-install-001) RECIPE="recipes/experiments/$EXP.yaml";;
  *) echo "RUNTIME FAIL: unknown experiment $EXP" >&2; exit 2;;
esac
command -v yq >/dev/null || { echo 'RUNTIME FAIL: yq missing'; exit 1; }
command -v limactl >/dev/null || { echo 'RUNTIME FAIL: limactl missing'; exit 1; }
[ -s "$RECIPE" ] || { echo "RUNTIME FAIL: missing $RECIPE"; exit 1; }
[ -s recipes/lima/security-research.yaml ] || { echo 'RUNTIME FAIL: missing Lima recipe'; exit 1; }

RUN="runs/$SESSION"
./scripts/session.sh create "$EXP" "${CUSIMANSE_PRIMARY_AGENT:-goose}" "$SESSION" >/dev/null
printf '%s\n' "experiment: $EXP" "configuration: $RECIPE" > "$RUN/evidence/index.yaml"
./scripts/session.sh checkpoint "$SESSION" VALIDATED
limactl validate recipes/lima/security-research.yaml
VM="cusimanse-$SESSION"
cleanup() { limactl delete --force "$VM" >/dev/null 2>&1 || true; }
trap cleanup EXIT

./scripts/session.sh checkpoint "$SESSION" PROVISIONED
limactl start --name="$VM" recipes/lima/security-research.yaml
./scripts/session.sh checkpoint "$SESSION" INSTRUMENTED
limactl shell "$VM" -- bash -lc 'date -u +%Y-%m-%dT%H:%M:%SZ; ps -ef; ss -tunap' > "$RUN/evidence/pre-workload.txt" 2>&1 || true
./scripts/session.sh checkpoint "$SESSION" EXECUTING

case "$EXP" in
  go-install-001)
    limactl shell "$VM" -- bash -lc 'set -e; go version; test -d /workspace/packages/labprobe; cd /workspace/packages/labprobe; go install .; command -v labprobe; labprobe' > "$RUN/evidence/workload.txt" 2>&1
    ;;
  npm-install-001)
    limactl shell "$VM" -- bash -lc 'set -e; node --version; npm --version; mkdir -p /tmp/npm-test; cd /tmp/npm-test; npm init -y; npm install lodash@4.17.21 --ignore-scripts' > "$RUN/evidence/workload.txt" 2>&1
    ;;
esac
limactl shell "$VM" -- bash -lc 'ps -ef; ss -tunap; find /tmp/cusimanse-lab /tmp/npm-test -maxdepth 3 -type f -print 2>/dev/null | sort' > "$RUN/evidence/post-workload.txt" 2>&1 || true
./scripts/session.sh checkpoint "$SESSION" EVIDENCE_COLLECTED
./scripts/session.sh hash "$SESSION"
./scripts/session.sh checkpoint "$SESSION" ANALYZING
cat > "$RUN/analysis/summary.md" <<EOF
# Analysis

Experiment: $EXP

Evidence was collected from the disposable VM. The primary agent's evidence-analysis subrecipe must distinguish observations from inference and cite raw artifacts.
EOF
./scripts/session.sh checkpoint "$SESSION" VERIFYING
cat > "$RUN/verification/result.md" <<'EOF'
# Verification

Status: PENDING_INDEPENDENT_REVIEW

The primary agent must run the independent verification subrecipe before this session can be marked COMPLETE.
EOF
./scripts/session.sh checkpoint "$SESSION" REPORTED
cat > "$RUN/research-report/report.md" <<EOF
# Cusimanse Research Report

Experiment: $EXP
Session: $SESSION

Status: PENDING_INDEPENDENT_REVIEW

Evidence is preserved under `evidence/`. The report is not final until independent verification is recorded.
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
printf 'RUNTIME PARTIAL: VM lifecycle/evidence capture completed; independent agent verification and final report completion remain required. Session: %s\n' "$RUN"
