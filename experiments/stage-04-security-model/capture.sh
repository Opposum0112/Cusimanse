#!/usr/bin/env bash
set -euo pipefail
echo "capture stage-04-security-model"
echo "Instrumentation: security-events"
echo "Start collectors BEFORE the target. Prefer VM-side strace/tcpdump."
echo "Do not capture host credential files."
