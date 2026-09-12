#!/usr/bin/env bash
# Source this file: source scripts/env.sh
CUSIMANSE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CUSIMANSE_ROOT
export PATH="$CUSIMANSE_ROOT/scripts:$CUSIMANSE_ROOT/scripts/tests:$HOME/.local/bin:$PATH"
export CUSIMANSE_BIN="$CUSIMANSE_ROOT/scripts"
