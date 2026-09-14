#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${CUSIMANSE_CONFIG_ROOT:-$HOME/.config/cusimanse}"
DATA="${CUSIMANSE_DATA_ROOT:-$HOME/.local/share/cusimanse}"
NUMBAT_FILE="${NUMBAT_RECORD_FILE:-$HOME/.numbat/cusimanse.ndjson}"
usage(){ cat <<'EOF'
Usage:
  scripts/observability.sh status     Show configured observability endpoints and local artifacts.
  scripts/observability.sh numbat     Print Numbat record path and recent records.
  scripts/observability.sh phoenix    Print Phoenix UI/OTLP endpoints.
  scripts/observability.sh clawmetry  Print ClawMetry UI endpoint and token snapshot locations.
  scripts/observability.sh report SESSION-ID  Show report and verification paths.
EOF
}
status(){
  echo "config=$CONFIG"; echo "data=$DATA"; echo "numbat=$NUMBAT_FILE"
  [ -f "$CONFIG/observability.env" ] && sed -E 's/(API_KEY|TOKEN|SECRET|PASSWORD)=.*/\1=<redacted>/' "$CONFIG/observability.env" || true
  for p in 6006 8900 4318; do if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 1 "http://127.0.0.1:$p" >/dev/null 2>&1; then echo "localhost:$p=UP"; else echo "localhost:$p=DOWN"; fi; done
}
numbat(){ echo "Numbat records: $NUMBAT_FILE"; [ -f "$NUMBAT_FILE" ] && tail -n 20 "$NUMBAT_FILE" || echo 'No Numbat records yet.'; }
phoenix(){ echo 'Phoenix UI: http://127.0.0.1:6006'; echo 'OTLP HTTP: http://127.0.0.1:4318'; }
clawmetry(){ echo 'ClawMetry UI: http://127.0.0.1:8900'; echo 'Per-run token snapshot: runs/<session-id>/observability/token-usage.yaml'; }
report(){ sid="$1"; [ -n "$sid" ] || { usage; exit 2; }; base="$ROOT/runs/$sid"; for f in research-report/report.md research-report/report.yaml verification/result.md preservation/manifest.yaml observability/token-usage.yaml; do printf '%s: ' "$f"; [ -f "$base/$f" ] && echo "$base/$f" || echo 'MISSING'; done; }
case "${1:-status}" in status) status;; numbat) numbat;; phoenix) phoenix;; clawmetry) clawmetry;; report) shift; report "$@";; *) usage; exit 2;; esac
