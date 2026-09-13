#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADDR="${CUSIMANSE_TOKEN_DASHBOARD_ADDR:-127.0.0.1:8787}"
DATA="${CUSIMANSE_TOKEN_USAGE_FILE:-$ROOT/reports/token-usage/usage.json}"
POLICYCTL="${POLICYCTL_BIN:-$ROOT/policyctl}"
if [ ! -x "$POLICYCTL" ]; then
  echo "policyctl not found; build with: go build -o policyctl ./cmd/policyctl" >&2
  exit 1
fi
mkdir -p "$(dirname "$DATA")"
if [ ! -f "$DATA" ]; then
  printf '%s\n' '{"sessions":[],"totals":{"input_tokens":0,"output_tokens":0,"total_tokens":0}}' > "$DATA"
fi
python3 - "$DATA" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    value = json.load(f)
if not isinstance(value, (dict, list)):
    raise SystemExit("token usage file must contain a JSON object or array")
PY
printf 'Token usage dashboard validation PASS: %s\n' "$DATA"
exec "$POLICYCTL" token-dashboard --addr "$ADDR" --data "$DATA"
