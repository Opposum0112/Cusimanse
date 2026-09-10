#!/usr/bin/env bash
set -euo pipefail
echo "run stage-01-architecture"
echo "Approved target:"
echo "  python3 -m labctl stage run 01"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
