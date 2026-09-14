#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
RECIPE="$ROOT/recipes/host/security-research.yaml"
CONFIG="${CUSIMANSE_CONFIG_ROOT:-$HOME/.config/cusimanse}"
VENV="${CUSIMANSE_PYTHON_ENV:-$HOME/.local/share/cusimanse/venv}"
usage(){ cat <<'USAGE'
Usage:
  ./scripts/tools.sh list       List declared host, guest and service capabilities.
  ./scripts/tools.sh versions   Show installed command versions and paths.
  ./scripts/tools.sh config     Show non-secret configuration locations.
  ./scripts/tools.sh path       Show the executable PATH used by Cusimanse.
  ./scripts/tools.sh check      Fail if required host capabilities are missing.
  ./scripts/tools.sh observability  Show observability endpoint status.
  ./scripts/tools.sh numbat      Show recent Numbat records.
USAGE
}
[ -s "$RECIPE" ] || { echo "Missing host recipe: $RECIPE" >&2; exit 1; }
command -v yq >/dev/null 2>&1 || { echo "yq is required to read $RECIPE" >&2; exit 1; }
platform(){ case "$(uname -s)" in Linux) echo linux;; Darwin) echo macos;; MINGW*|MSYS*|CYGWIN*) echo windows_native;; *) echo windows_wsl2;; esac; }
host_commands(){ yq -r '.common.commands[], .platforms["'"$(platform)"'"].commands[]' "$RECIPE" 2>/dev/null | awk 'NF && !seen[$0]++'; }
guest_commands(){ yq -r '.guest.commands[]' "$RECIPE"; }
services(){ yq -r '.mandatory_services.gateways[], .mandatory_services.observability[], .mandatory_services.primary_agent' "$RECIPE"; }
list_tools(){
  printf '%-30s %-12s %s\n' CAPABILITY STATUS SOURCE
  while IFS= read -r tool; do [ -n "$tool" ] || continue; if command -v "$tool" >/dev/null 2>&1; then status=INSTALLED; else status=MISSING; fi; printf '%-30s %-12s host-recipe\n' "$tool" "$status"; done < <(host_commands)
  while IFS= read -r tool; do printf '%-30s %-12s guest-only\n' "$tool" DECLARED; done < <(guest_commands)
  while IFS= read -r tool; do [ -n "$tool" ] || continue; if command -v "$tool" >/dev/null 2>&1; then status=INSTALLED; else status=MISSING; fi; printf '%-30s %-12s mandatory-service\n' "$tool" "$status"; done < <(services)
  for pkg in $(yq -r '.common.python_packages[]' "$RECIPE"); do if [ -x "$VENV/bin/pip" ] && "$VENV/bin/pip" show "$pkg" >/dev/null 2>&1; then status=INSTALLED; else status=MISSING; fi; printf '%-30s %-12s python-venv\n' "python:$pkg" "$status"; done
  printf '%-30s %-12s %s\n' host:aegis "$([ -d "$HOME/.local/share/cusimanse/aegis/.git" ] && echo INSTALLED || echo MISSING)" host-recipe
}
versions(){ while IFS= read -r tool; do if command -v "$tool" >/dev/null 2>&1; then printf '\n[%s] %s\n' "$tool" "$(command -v "$tool")"; "$tool" --version 2>&1 | head -n 2 || "$tool" version 2>&1 | head -n 2 || true; fi; done < <(host_commands); }
config(){ printf 'Configuration: %s\nGateway: %s\nObservability: %s\nGoose: %s\nAegis: %s\nPython environment: %s\n' "$CONFIG" "$CONFIG/litellm.yaml" "$CONFIG/observability.env" "$CONFIG/goose.env" "$HOME/.local/share/cusimanse/aegis/" "$VENV"; }
check(){ local missing=0; while IFS= read -r tool; do command -v "$tool" >/dev/null 2>&1 || { echo "MISSING host command: $tool" >&2; missing=1; }; done < <(host_commands); [ "$missing" -eq 0 ] || exit 1; echo 'HOST TOOLS PASS'; }
case "${1:-list}" in list) list_tools;; versions) versions;; config) config;; path) printf '%s\n' "$PATH" | tr ':' '\n';; check) check;; observability) "$ROOT/scripts/observability.sh" status;; numbat) "$ROOT/scripts/observability.sh" numbat;; *) usage; exit 2;; esac
