#!/usr/bin/env bash
set -euo pipefail
echo "run stage-05-multi-agent"
echo "Approved target:"
echo "  python3 -m labctl stage run 05"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
