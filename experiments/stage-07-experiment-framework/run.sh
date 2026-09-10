#!/usr/bin/env bash
set -euo pipefail
echo "run stage-07-experiment-framework"
echo "Approved target:"
echo "  python3 -m labctl experiment list"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
