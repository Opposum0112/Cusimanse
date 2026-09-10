#!/usr/bin/env bash
# Shared host-side helpers. Sourced by experiment scripts on the lab host.
set -euo pipefail

lab_root() {
  local here="$1"
  (cd "$here" && while [[ ! -f LICENSE || ! -f AGENTS.md ]]; do
    cd ..
    if [[ "$(pwd)" == "/" ]]; then
      echo "labctl: repository root not found" >&2
      return 1
    fi
  done
  pwd)
}

log() { printf '[labctl] %s\n' "$*"; }
die() { printf '[labctl] ERROR: %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

utc_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
