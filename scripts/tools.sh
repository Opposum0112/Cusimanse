#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
RECIPE="$ROOT/recipes/host/security-research.yaml"
CONFIG="$HOME/.config/cusimanse"
VENV="$HOME/.local/share/cusimanse/venv"

usage(){ cat <<'USAGE'
Usage:
  ./scripts/tools.sh list       List every declared host capability and status.
  ./scripts/tools.sh versions   Show installed command versions and paths.
  ./scripts/tools.sh config     Show non-secret configuration locations.
  ./scripts/tools.sh path       Show the executable PATH used by Cusimanse.
  ./scripts/tools.sh check      Fail if any required host capability is missing.
USAGE
}
[ -f "$RECIPE" ] || { echo "Missing host recipe: $RECIPE" >&2; exit 1; }
command -v yq >/dev/null 2>&1 || { echo "yq is required to read $RECIPE" >&2; exit 1; }
list_commands(){ yq -r '.required.commands[]' "$RECIPE"; }
list_tools(){
  printf '%-30s %-12s %s\n' CAPABILITY STATUS SOURCE
  printf '%-30s %-12s %s\n' '------------------------------' '------------' '------'
  while IFS= read -r tool; do
    if command -v "$tool" >/dev/null 2>&1; then status=INSTALLED; else status=MISSING; fi
    printf '%-30s %-12s %s\n' "$tool" "$status" "$RECIPE"
  done < <(list_commands)
  while IFS= read -r pkg; do
    if [ -x "$VENV/bin/pip" ] && "$VENV/bin/pip" show "$pkg" >/dev/null 2>&1; then status=INSTALLED; else status=MISSING; fi
    printf '%-30s %-12s %s\n' "python:$pkg" "$status" "$RECIPE"
  done < <(yq -r '.required.python_packages[]' "$RECIPE")
  if [ -d "$HOME/.local/share/cusimanse/aegis/.git" ]; then status=INSTALLED; else status=MISSING; fi
  printf '%-30s %-12s %s\n' 'host:aegis' "$status" "$RECIPE"
}
case "${1:-list}" in
  list) list_tools ;;
  versions)
    while IFS= read -r tool; do
      if command -v "$tool" >/dev/null 2>&1; then
        printf '\n[%s] %s\n' "$tool" "$(command -v "$tool")"
        "$tool" --version 2>&1 | head -n 2 || "$tool" version 2>&1 | head -n 2 || true
      fi
    done < <(list_commands)
    ;;
  config)
    printf 'Configuration directory: %s\n' "$CONFIG"
    for f in "$CONFIG"/*; do [ -e "$f" ] && printf '  %s\n' "$f"; done
    printf 'Aegis checkout: %s\n' "$HOME/.local/share/cusimanse/aegis/"
    printf 'Python environment: %s\n' "$VENV/"
    printf '\nSecrets are not printed. Environment files:\n'
    printf '  source ~/.config/cusimanse/goose.env\n'
    printf '  source ~/.config/cusimanse/observability.env\n'
    printf '  source ~/.config/cusimanse/omniroute.env\n'
    ;;
  path) printf '%s\n' "$PATH" | tr ':' '\n' ;;
  check)
    missing=0
    while IFS= read -r tool; do command -v "$tool" >/dev/null 2>&1 || { echo "MISSING: $tool" >&2; missing=1; }; done < <(list_commands)
    [ "$missing" -eq 0 ] || exit 1
    list_tools >/dev/null
    echo 'HOST TOOLS PASS'
    ;;
  *) usage; exit 2 ;;
esac
