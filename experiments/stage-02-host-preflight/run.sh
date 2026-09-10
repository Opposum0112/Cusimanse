#!/usr/bin/env bash
set -euo pipefail
echo "run stage-02-host-preflight"
echo "Approved target:"
echo "  python3 -m labctl preflight"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
