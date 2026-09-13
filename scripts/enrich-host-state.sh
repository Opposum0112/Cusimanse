#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="${CUSIMANSE_HOST_STATE:-$ROOT/reports/host-state.yaml}"
mkdir -p "$(dirname "$STATE")"
[ -f "$STATE" ] || printf 'schema: cusimanse.host-state/v1\n' > "$STATE"
if ! grep -q '^token_usage:' "$STATE"; then
  cat >> "$STATE" <<'EOF'
token_usage:
  dashboard_command: cusimanse-token-dashboard
  ledger: reports/token-usage/usage.json
  environment_file: ~/.config/cusimanse/token-optimization.env
  tools: [ponytail, numbat, miller]
  authorization: false
  fallback: declarative-only
EOF
fi
