#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SELECTED_FILE="$ROOT/.cusimanse/primary-agent.yaml"
[ -f "$SELECTED_FILE" ] || { echo 'Agent preflight FAIL: primary adapter is not selected' >&2; exit 1; }
PRIMARY=$(awk '$1 == "primary_adapter:" {print $2}' "$SELECTED_FILE")
[ -n "$PRIMARY" ] || { echo 'Agent preflight FAIL: primary_adapter missing' >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }
case "$PRIMARY" in
  goose) have goose || exit 1 ;;
  opencode) have opencode || exit 1 ;;
  pi) have pi || exit 1 ;;
  hermes) have hermes || { echo 'Agent preflight: hermes NOT_DEPLOYED'; exit 0; } ;;
  codex) have codex || exit 1 ;;
  prime-intellect) have prime-agent || { echo 'Agent preflight: prime-intellect NOT_DEPLOYED'; exit 0; } ;;
  grok-build|antigravity|claude-code|devin) echo "Agent preflight: $PRIMARY provider/manual configuration must be completed outside git"; exit 0 ;;
  *) echo "Agent preflight FAIL: unknown adapter $PRIMARY" >&2; exit 1;;
esac

test -f "$ROOT/recipes/agents/primary-agent.yaml"
test -f "$ROOT/recipes/agents/learning-loop.yaml"
test -f "$ROOT/recipes/agent-selection.yaml"
test -f "$ROOT/recipes/adapters/hermes.yaml"
test -f "$ROOT/policies/host-policy.yaml"
command -v limactl >/dev/null 2>&1
echo "Agent preflight PASS: $PRIMARY binary and Cusimanse contracts are available"
