#!/usr/bin/env bash
set -euo pipefail
RUN_DIR="${1:-}"
[ -n "$RUN_DIR" ] || { echo 'usage: ./scripts/verify-run.sh <run-directory>' >&2; exit 2; }
[ -d "$RUN_DIR" ] || { echo "VERIFY FAIL: missing run directory: $RUN_DIR" >&2; exit 1; }
for f in run.yaml; do [ -s "$RUN_DIR/$f" ] || { echo "VERIFY FAIL: missing $f" >&2; exit 1; }; done
[ -d "$RUN_DIR/evidence" ] || { echo 'VERIFY FAIL: missing evidence/' >&2; exit 1; }
[ -d "$RUN_DIR/provenance" ] || { echo 'VERIFY FAIL: missing provenance/' >&2; exit 1; }
[ -s "$RUN_DIR/provenance/hashes.sha256" ] || { echo 'VERIFY FAIL: missing provenance/hashes.sha256' >&2; exit 1; }
[ -d "$RUN_DIR/analysis" ] || { echo 'VERIFY FAIL: missing analysis/' >&2; exit 1; }
[ -d "$RUN_DIR/verification" ] || { echo 'VERIFY FAIL: missing verification/' >&2; exit 1; }
[ -d "$RUN_DIR/research-report" ] || { echo 'VERIFY FAIL: missing research-report/' >&2; exit 1; }
( cd "$RUN_DIR" && sha256sum -c provenance/hashes.sha256 )
printf 'VERIFY PASS: run structure, evidence and SHA-256 provenance are valid: %s\n' "$RUN_DIR"
