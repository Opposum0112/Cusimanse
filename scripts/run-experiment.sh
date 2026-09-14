#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
usage(){ echo "usage: $0 <go-install-001|npm-install-001|npm-lifecycle-001> [session-id]"; exit 2; }
fail(){ echo "EXPERIMENT FAIL: $*" >&2; exit 1; }
[ $# -ge 1 ] || usage
EXP="$1"; SESSION="${2:-$(date -u +%Y%m%dT%H%M%SZ)-$1}"
case "$EXP" in go-install-001|npm-install-001|npm-lifecycle-001) CONFIG="recipes/experiments/$EXP.yaml";; *) fail "unknown experiment $EXP";; esac
for t in yq limactl; do command -v "$t" >/dev/null 2>&1 || fail "$t missing; run ./scripts/install.sh"; done
[ -s "$CONFIG" ] || fail "missing $CONFIG"
RECIPE="recipes/$EXP/recipe.yaml"
command -v goose >/dev/null 2>&1 || fail 'Goose is required; run ./scripts/install.sh'
goose recipe validate "$RECIPE"
RUN="runs/$SESSION"
./scripts/session.sh create "$EXP" "${CUSIMANSE_PRIMARY_AGENT:-goose}" "$SESSION" >/dev/null
printf '%s\n' "experiment: $EXP" "configuration: $CONFIG" "goose_recipe: $RECIPE" "instrumentation: recipes/instrumentation/security-research.yaml" "collector_policy: collectors-start-before-workload" > "$RUN/evidence/index.yaml"
./scripts/session.sh checkpoint "$SESSION" VALIDATED
./scripts/session.sh checkpoint "$SESSION" PREFLIGHTED
./scripts/session.sh checkpoint "$SESSION" PLANNED
./scripts/session.sh checkpoint "$SESSION" AWAITING_APPROVAL
./scripts/session.sh checkpoint "$SESSION" APPROVED
limactl validate recipes/lima/security-research.yaml
VM="cusimanse-$SESSION"
cleanup(){ limactl delete --force "$VM" >/dev/null 2>&1 || true; }
trap cleanup EXIT
./scripts/session.sh checkpoint "$SESSION" PROVISIONED
limactl start --name="$VM" recipes/lima/security-research.yaml
./scripts/session.sh checkpoint "$SESSION" INSTRUMENTED
# The instrumentation profile is guest-scoped. These collectors start before the workload.
limactl shell "$VM" -- bash -lc 'set -e; date -u +%Y-%m-%dT%H:%M:%SZ > /tmp/cusimanse-start-time; ps -ef > /tmp/cusimanse-process-before; ss -tunap > /tmp/cusimanse-network-before || true; find /workspace -xdev -type f -print 2>/dev/null | sort > /tmp/cusimanse-files-before || true; if command -v tcpdump >/dev/null && sudo -n true 2>/dev/null; then sudo -n tcpdump -i any -U -w /tmp/cusimanse-network.pcap >/tmp/cusimanse-tcpdump.log 2>&1 & echo $! > /tmp/cusimanse-tcpdump.pid; fi' || fail 'failed to start guest collectors'
if [ "$EXP" = go-install-001 ]; then
  tar -C packages -cf - labprobe | limactl shell "$VM" -- bash -lc 'mkdir -p /workspace/packages && tar -xf - -C /workspace/packages'
elif [ "$EXP" = npm-lifecycle-001 ]; then
  tar -C packages -cf - npm-fixture | limactl shell "$VM" -- bash -lc 'mkdir -p /workspace/packages && tar -xf - -C /workspace/packages'
fi
./scripts/session.sh checkpoint "$SESSION" EXECUTING
set +e
case "$EXP" in
  go-install-001) limactl shell "$VM" -- bash -lc 'set -e; cd /workspace/packages/labprobe; strace -ff -o /tmp/cusimanse-strace go install .; command -v labprobe; labprobe' > "$RUN/evidence/workload.txt" 2>&1 ;;
  npm-install-001) limactl shell "$VM" -- bash -lc 'set -e; node --version; npm --version; mkdir -p /tmp/npm-test; cd /tmp/npm-test; npm init -y; strace -ff -o /tmp/cusimanse-strace npm install lodash@4.17.21 --ignore-scripts' > "$RUN/evidence/workload.txt" 2>&1 ;;
  npm-lifecycle-001) limactl shell "$VM" -- bash -lc 'set -e; node --version; npm --version; mkdir -p /tmp/npm-lifecycle; cd /tmp/npm-lifecycle; npm init -y; strace -ff -o /tmp/cusimanse-strace npm install /workspace/packages/npm-fixture; test -f /tmp/cusimanse-npm-lifecycle-marker' > "$RUN/evidence/workload.txt" 2>&1 ;;
esac
rc=$?
set -e
limactl shell "$VM" -- bash -lc 'if [ -s /tmp/cusimanse-tcpdump.pid ]; then kill "$(cat /tmp/cusimanse-tcpdump.pid)" 2>/dev/null || true; fi; date -u +%Y-%m-%dT%H:%M:%SZ > /tmp/cusimanse-end-time; ps -ef > /tmp/cusimanse-process-after; ss -tunap > /tmp/cusimanse-network-after || true; find /workspace -xdev -type f -print 2>/dev/null | sort > /tmp/cusimanse-files-after || true; sha256sum /tmp/cusimanse-strace* /tmp/cusimanse-network.pcap 2>/dev/null > /tmp/cusimanse-collector-hashes || true' || true
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-process-before /tmp/cusimanse-process-after' > "$RUN/evidence/process.txt" 2>&1 || true
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-network-before /tmp/cusimanse-network-after' > "$RUN/evidence/network.txt" 2>&1 || true
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-files-before /tmp/cusimanse-files-after' > "$RUN/evidence/filesystem.txt" 2>&1 || true
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-strace* 2>/dev/null' > "$RUN/evidence/syscalls.txt" 2>&1 || true
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-collector-hashes /tmp/cusimanse-tcpdump.log 2>/dev/null' > "$RUN/evidence/collector-hashes.txt" 2>&1 || true
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-npm-lifecycle-marker 2>/dev/null' > "$RUN/evidence/lifecycle-marker.txt" 2>&1 || true
limactl shell "$VM" -- bash -lc 'cat /tmp/cusimanse-start-time /tmp/cusimanse-end-time' > "$RUN/evidence/timestamps.txt" 2>&1 || true
./scripts/session.sh checkpoint "$SESSION" EVIDENCE_COLLECTED
./scripts/session.sh hash "$SESSION"
if [ "$rc" -ne 0 ]; then
  ./scripts/session.sh checkpoint "$SESSION" FAILED || true
  echo "RUNTIME FAIL: workload exited with status $rc; evidence preserved at $RUN" >&2
  exit "$rc"
fi
# Runtime harness stops at evidence collection. Goose or another primary agent owns analysis,
# independent verification, report generation and final lifecycle checkpoints.
cat > "$RUN/analysis/summary.md" <<EOF
# Analysis status

Experiment: $EXP

Status: PENDING_AGENT_ANALYSIS

The deterministic runtime harness collected raw evidence. The selected primary agent must analyze it using the evidence-analysis subrecipe and replace this status with cited observations and inference.
EOF
cat > "$RUN/verification/result.md" <<'EOF'
# Verification status

Status: PENDING_INDEPENDENT_REVIEW

The selected primary agent must run the verification subrecipe independently of analysis and replace this status with the verification result.
EOF
cat > "$RUN/research-report/report.md" <<EOF
# Cusimanse Research Report

Experiment: $EXP
Session: $SESSION

Status: PENDING_AGENT_ANALYSIS_AND_VERIFICATION

Raw evidence is preserved under `evidence/`. This is not a final research conclusion.
EOF
cat > "$RUN/research-report/report.yaml" <<EOF
experiment: $EXP
session_id: $SESSION
status: PENDING_AGENT_ANALYSIS_AND_VERIFICATION
evidence: evidence/
EOF
./scripts/session.sh checkpoint "$SESSION" ANALYZING
./scripts/session.sh checkpoint "$SESSION" VERIFYING
./scripts/session.sh hash "$SESSION"
./scripts/session.sh checkpoint "$SESSION" PRESERVED
./scripts/session.sh verify-layout "$SESSION"
# Do not claim REPORTED/COMPLETE: the primary agent must replace the provisional artifacts,
# independently verify them, then advance the session through REPORTED -> DESTROYED -> COMPLETE.
printf 'RUNTIME PARTIAL: deterministic disposable-VM execution, declared collector capture and hashing completed. Agent analysis, independent verification and final report remain required. Session: %s\n' "$RUN"
