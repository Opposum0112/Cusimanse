#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
usage(){ echo "usage: $0 <go-install-001|npm-install-001|npm-lifecycle-001|npm-threat-001> [session-id]"; exit 2; }
fail(){ echo "EXPERIMENT FAIL: $*" >&2; exit 1; }
[ $# -ge 1 ] || usage
EXP="$1"; SESSION="${2:-$(date -u +%Y%m%dT%H%M%SZ)-$1}"
case "$EXP" in go-install-001|npm-install-001|npm-lifecycle-001|npm-threat-001) CONFIG="recipes/experiments/$EXP.yaml";; *) fail "unknown experiment $EXP";; esac
for t in yq limactl goose; do command -v "$t" >/dev/null 2>&1 || fail "$t missing; run ./scripts/install.sh"; done
[ -s "$CONFIG" ] || fail "missing $CONFIG"
HOST_PROFILE="$(yq -r '.profiles.host' "$CONFIG")"
WORKLOAD_PROFILE="$(yq -r '.profiles.workload' "$CONFIG")"
[ -s "$HOST_PROFILE" ] || fail "missing host profile $HOST_PROFILE"
[ -s "$WORKLOAD_PROFILE" ] || fail "missing workload profile $WORKLOAD_PROFILE"
[ "$(yq -r '.kind' "$HOST_PROFILE")" = "host-profile" ] || fail "invalid host profile kind"
[ "$(yq -r '.kind' "$WORKLOAD_PROFILE")" = "workload-profile" ] || fail "invalid workload profile kind"
[ "$(yq -r '.agent_may_generate_provisioning' "$HOST_PROFILE")" = "false" ] || fail "host profile permits agent-generated provisioning"
[ "$(yq -r '.agent_may_generate_instrumentation' "$HOST_PROFILE")" = "false" ] || fail "host profile permits agent-generated instrumentation"
HANDLER="$(yq -r '.runtime_handler' "$WORKLOAD_PROFILE")"
case "$HANDLER" in go-install|npm-install|npm-lifecycle|npm-threat) ;; *) fail "unsupported/non-deterministic workload handler: $HANDLER";; esac
INSTRUMENTATION="$(yq -r '.instrumentation' "$WORKLOAD_PROFILE")"
[ -s "$INSTRUMENTATION" ] || fail "missing workload instrumentation profile $INSTRUMENTATION"
RECIPE="recipes/$EXP/recipe.yaml"
goose recipe validate "$RECIPE"
RUN="runs/$SESSION"
./scripts/session.sh create "$EXP" "${CUSIMANSE_PRIMARY_AGENT:-goose}" "$SESSION" >/dev/null
printf '%s\n' "experiment: $EXP" "configuration: $CONFIG" "host_profile: $HOST_PROFILE" "workload_profile: $WORKLOAD_PROFILE" "goose_recipe: $RECIPE" "instrumentation: $INSTRUMENTATION" "runtime_mode: deterministic-profile-handler" > "$RUN/evidence/index.yaml"
./scripts/session.sh checkpoint "$SESSION" VALIDATED
./scripts/session.sh checkpoint "$SESSION" PREFLIGHTED
./scripts/session.sh checkpoint "$SESSION" PLANNED
./scripts/session.sh checkpoint "$SESSION" AWAITING_APPROVAL
./scripts/session.sh checkpoint "$SESSION" APPROVED
HOST_RECIPE="$(yq -r '.compute_recipe' "$HOST_PROFILE")"
[ -s "$HOST_RECIPE" ] || fail "missing compute recipe from host profile: $HOST_RECIPE"
limactl validate "$HOST_RECIPE"
VM="cusimanse-$SESSION"
cleanup(){ limactl delete --force "$VM" >/dev/null 2>&1 || true; }
trap cleanup EXIT
./scripts/session.sh checkpoint "$SESSION" PROVISIONED
limactl start --name="$VM" "$HOST_RECIPE"
./scripts/session.sh checkpoint "$SESSION" INSTRUMENTED
limactl shell "$VM" -- bash -lc 'set -e; date -u +%Y-%m-%dT%H:%M:%SZ > /tmp/cusimanse-start-time; ps -ef > /tmp/cusimanse-process-before; ss -tunap > /tmp/cusimanse-network-before || true; find /workspace -xdev -type f -print 2>/dev/null | sort > /tmp/cusimanse-files-before || true; if command -v tcpdump >/dev/null && sudo -n true 2>/dev/null; then sudo -n tcpdump -i any -U -w /tmp/cusimanse-network.pcap >/tmp/cusimanse-tcpdump.log 2>&1 & echo $! > /tmp/cusimanse-tcpdump.pid; fi' || fail 'failed to start guest collectors'
case "$HANDLER" in
  go-install) tar -C packages -cf - labprobe | limactl shell "$VM" -- bash -lc 'mkdir -p /workspace/packages && tar -xf - -C /workspace/packages' ;;
  npm-lifecycle|npm-threat) tar -C packages -cf - npm-fixture | limactl shell "$VM" -- bash -lc 'mkdir -p /workspace/packages && tar -xf - -C /workspace/packages' ;;
esac
./scripts/session.sh checkpoint "$SESSION" EXECUTING
set +e
case "$HANDLER" in
  go-install) limactl shell "$VM" -- bash -lc 'set -e; cd /workspace/packages/labprobe; strace -ff -o /tmp/cusimanse-strace go install .; command -v labprobe; labprobe' > "$RUN/evidence/workload.txt" 2>&1 ;;
  npm-install) limactl shell "$VM" -- bash -lc 'set -e; node --version; npm --version; mkdir -p /tmp/npm-test; cd /tmp/npm-test; npm init -y; strace -ff -o /tmp/cusimanse-strace npm install lodash@4.17.21 --ignore-scripts' > "$RUN/evidence/workload.txt" 2>&1 ;;
  npm-lifecycle) limactl shell "$VM" -- bash -lc 'set -e; node --version; npm --version; mkdir -p /tmp/npm-lifecycle; cd /tmp/npm-lifecycle; npm init -y; strace -ff -o /tmp/cusimanse-strace npm install /workspace/packages/npm-fixture; test -f /tmp/cusimanse-npm-lifecycle-marker' > "$RUN/evidence/workload.txt" 2>&1 ;;
  npm-threat) limactl shell "$VM" -- bash -lc 'set -e; node --version; npm --version; mkdir -p /tmp/npm-threat; cd /tmp/npm-threat; npm init -y; strace -ff -o /tmp/cusimanse-strace npm install /workspace/packages/npm-fixture; test -f /tmp/cusimanse-npm-lifecycle-marker' > "$RUN/evidence/workload.txt" 2>&1 ;;
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
cat > "$RUN/analysis/summary.md" <<EOF
# Analysis status

Experiment: $EXP

Status: PENDING_AGENT_ANALYSIS

Raw evidence was collected by the deterministic runtime harness. The selected primary agent must analyze the evidence using the registered evidence-analysis subrecipe and replace this status with cited observations and inference.
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

Raw evidence is preserved under evidence/. This is not a final research conclusion.
EOF
cat > "$RUN/research-report/report.yaml" <<EOF
experiment: $EXP
session_id: $SESSION
status: PENDING_AGENT_ANALYSIS_AND_VERIFICATION
evidence: evidence/
EOF
./scripts/session.sh verify-layout "$SESSION"
printf 'RUNTIME PARTIAL: deterministic profile-selected disposable-VM execution, declared collector capture and hashing completed at EVIDENCE_COLLECTED. Agent analysis, independent verification, final report, preservation and destruction remain required. Session: %s\n' "$RUN"
