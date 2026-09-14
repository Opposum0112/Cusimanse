#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

usage() { echo "usage: $0 <go-install-001|npm-install-001> [session-id]"; exit 2; }
[ $# -ge 1 ] || usage
EXP="$1"; SESSION="${2:-$(date -u +%Y%m%dT%H%M%SZ)-$$}"
case "$EXP" in
  go-install-001) RECIPE="recipes/experiments/go-install-001.yaml"; VM_RECIPE="recipes/lima/security-research.yaml";;
  npm-install-001) RECIPE="recipes/experiments/npm-install-001.yaml"; VM_RECIPE="recipes/lima/security-research.yaml";;
  *) echo "RUNTIME FAIL: unknown experiment $EXP" >&2; exit 2;;
esac
command -v yq >/dev/null || { echo 'RUNTIME FAIL: yq missing'; exit 1; }
command -v limactl >/dev/null || { echo 'RUNTIME FAIL: limactl missing'; exit 1; }
[ -s "$RECIPE" ] || { echo "RUNTIME FAIL: missing $RECIPE"; exit 1; }
[ -s "$VM_RECIPE" ] || { echo 'RUNTIME FAIL: missing Lima recipe'; exit 1; }

RUN="runs/$SESSION"
VM="cusimanse-$SESSION"
mkdir -p "$RUN/evidence/audit" "$RUN/provenance" "$RUN/analysis" "$RUN/verification" "$RUN/research-report" "$RUN/preservation" "$RUN/observability" "$RUN/learning/candidates" "$RUN/learning/evaluations" "$RUN/learning/replays" "$RUN/learning/verification" "$RUN/learning/promotions"
cat > "$RUN/session.yaml" <<EOF
session_id: $SESSION
experiment_id: $EXP
recipe: $RECIPE
session_state_contract: recipes/session/session-state.yaml
status: CREATED
started_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ) session CREATED" > "$RUN/evidence/audit/events.jsonl"

transition() { printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ) session $1" >> "$RUN/evidence/audit/events.jsonl"; sed -i "s/^status:.*/status: $1/" "$RUN/session.yaml"; }
cleanup() { limactl delete --force "$VM" >/dev/null 2>&1 || true; }
trap cleanup EXIT

transition VALIDATED
limactl validate "$VM_RECIPE"
transition PROVISIONED
limactl start --name="$VM" "$VM_RECIPE"
transition INSTRUMENTED

capture() {
  limactl shell "$VM" -- bash -lc "$1" >> "$RUN/evidence/"${2:-workload.txt} 2>&1 || true
}
capture 'date -u +%Y-%m-%dT%H:%M:%SZ; ps -ef; ss -tunap' pre-workload.txt
transition EXECUTING
case "$EXP" in
  go-install-001)
    limactl shell "$VM" -- bash -lc 'set -e; go version; mkdir -p /tmp/cusimanse-lab; cd /tmp/cusimanse-lab; cp -R /workspace/packages/labprobe . 2>/dev/null || true; if [ -d labprobe ]; then cd labprobe; go install .; command -v labprobe || true; labprobe; else echo "labprobe source unavailable in VM"; exit 1; fi' > "$RUN/evidence/workload.txt" 2>&1
    ;;
  npm-install-001)
    limactl shell "$VM" -- bash -lc 'set -e; node --version; npm --version; mkdir -p /tmp/npm-test; cd /tmp/npm-test; npm init -y; npm install lodash@4.17.21 --ignore-scripts' > "$RUN/evidence/workload.txt" 2>&1
    ;;
esac
capture 'ps -ef; ss -tunap; find /tmp/cusimanse-lab /tmp/npm-test -maxdepth 3 -type f -print 2>/dev/null | sort' post-workload.txt
transition EVIDENCE_COLLECTED
sha256sum "$RUN/evidence"/* > "$RUN/evidence/index.sha256" 2>/dev/null || true
sha256sum "$RUN/session.yaml" > "$RUN/provenance/manifest.sha256"
transition ANALYZING
cat > "$RUN/analysis/summary.md" <<EOF
# Analysis

Experiment: `$EXP`

Raw evidence was collected from the disposable VM before teardown. Analysis must distinguish observations from inference.
EOF
transition VERIFYING
cat > "$RUN/verification/result.md" <<EOF
# Verification

Status: PENDING_INDEPENDENT_REVIEW

This artifact is a placeholder for the independent verifier subrecipe. A runtime PASS requires independent verification.
EOF
transition REPORTED
cat > "$RUN/research-report/report.md" <<EOF
# Cusimanse Research Report

Experiment: `$EXP`
Session: `$SESSION`

## Result

Runtime evidence is preserved under `evidence/`. Independent verification is required before this report can be considered final.
EOF
cat > "$RUN/research-report/report.yaml" <<EOF
experiment: $EXP
session_id: $SESSION
verification: PENDING_INDEPENDENT_REVIEW
evidence: evidence/
EOF
cp "$RUN/evidence/index.sha256" "$RUN/preservation/manifest.yaml" 2>/dev/null || true
transition PRESERVED
transition DESTROYED
transition PARTIAL
printf 'RUNTIME PARTIAL: deterministic VM execution completed; agent independent-verification/report subrecipes remain required. Session: %s\n' "$RUN"
