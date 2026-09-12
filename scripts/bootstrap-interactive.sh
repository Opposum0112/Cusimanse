#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$ROOT/.cusimanse/generated"
mkdir -p "$STATE"

ask() {
  local name="$1" default="$2" answer
  read -r -p "$name [$default]: " answer || true
  printf '%s' "${answer:-$default}"
}

printf '%s\n' 'Cusimanse interactive bootstrap'
printf '%s\n' 'Selections are written to .cusimanse/generated/config.yaml and used by recipes.'

goose_mode="$(ask 'Goose adapter mode (headless/interactive)' 'headless')"
numbat="$(ask 'Install/configure Numbat agent observability? (yes/no)' 'yes')"
otel="$(ask 'Configure OpenTelemetry? (yes/no)' 'yes')"
metrics="$(ask 'Configure Prometheus metrics? (yes/no)' 'yes')"
gateway="$(ask 'Configure model gateway? (yes/no)' 'yes')"
governance="$(ask 'Enable AI-plane governance? (yes/no)' 'yes')"
skills="$(ask 'Enable skills registry? (yes/no)' 'yes')"
mcp="$(ask 'Enable MCP registry? (yes/no)' 'yes')"

cat > "$STATE/config.yaml" <<EOF
version: 1
kind: generated-config
adapter:
  goose:
    mode: $goose_mode
observability:
  numbat: $numbat
  opentelemetry: $otel
  prometheus: $metrics
model_gateway:
  enabled: $gateway
ai_governance:
  enabled: $governance
skills:
  enabled: $skills
mcp:
  enabled: $mcp
EOF

printf '%s\n' "Generated $STATE/config.yaml"
printf '%s\n' 'Next: run scripts/preflight.sh to apply policy and validate the selected configuration.'
