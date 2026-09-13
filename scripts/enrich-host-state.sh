#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$ROOT/recipes/host-state.yaml"
ENV_FILE="$HOME/.config/cusimanse/token-optimization.env"
[ -f "$STATE" ] || exit 0
python3 - "$STATE" "$ENV_FILE" <<'PY'
from pathlib import Path
import sys
state = Path(sys.argv[1])
env = Path(sys.argv[2]).expanduser()
text = state.read_text(encoding="utf-8")
if "token_usage:" in text:
    raise SystemExit(0)
block = """token_usage:\n  command: cusimanse-token-dashboard\n  policy_interface: policyctl token-dashboard\n  dashboard: http://127.0.0.1:8787\n  ledger: reports/token-usage/usage.json\n  environment_file: ~/.config/cusimanse/token-optimization.env\n  tools: [ponytail, numbat, miller]\n  environment_configured: %s\n  fallback: declarative-skill-guidance\n  authorization: false\n""" % str(env.exists()).lower()
marker = "evidence:\n"
if marker in text:
    text = text.replace(marker, block + marker, 1)
else:
    text += "\n" + block
state.write_text(text, encoding="utf-8")
PY
