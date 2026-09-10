#!/usr/bin/env bash
set -euo pipefail
echo "capture stage-11-antigravity"
echo "Instrumentation: filesystem"
echo "Start collectors BEFORE the target. Prefer VM-side strace/tcpdump."
echo "Do not capture host credential files."
