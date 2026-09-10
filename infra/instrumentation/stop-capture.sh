#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EXP="${1:-}"
OUT="${ROOT}/evidence/${EXP:-ad-hoc}/raw"
mkdir -p "${OUT}"
echo "stop-capture $(date -u +%Y-%m-%dT%H:%M:%SZ) exp=${EXP:-ad-hoc}" | tee "${OUT}/capture-stop.txt"
