#!/usr/bin/env bash
set -euo pipefail
echo "run stage-04-security-model"
echo "Approved target:"
echo "  python3 -m labctl policy check --action host-root"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
