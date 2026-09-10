#!/usr/bin/env bash
# Start host-side capture helpers. Prefer running the real collectors inside the VM.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EXP="${1:-}"
OUT="${ROOT}/evidence/${EXP:-ad-hoc}/raw"
mkdir -p "${OUT}"
echo "start-capture $(date -u +%Y-%m-%dT%H:%M:%SZ) exp=${EXP:-ad-hoc}" | tee "${OUT}/capture-start.txt"
echo "Implement VM-side collectors in experiments/<id>/capture.sh"
echo "Host captures are optional and must not include credential files."
