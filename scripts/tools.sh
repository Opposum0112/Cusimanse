#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
RECIPE="$ROOT/recipes/host/security-research.yaml"
CONFIG="$HOME/.config/cusimanse"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/tools.sh list       List declared host commands, Python packages and Aegis status.
  ./scripts/tools.sh config     Show non-secret Cusimanse configuration paths.
  ./scripts/tools.sh versions   Show versions/identity for installed host commands.
EOF
}

[ -f "$RECIPE" ] || { echo "Missing host recipe: $RECIPE" >&2; exit 1; }
command -v yq >/dev/null 2>&1 || { echo "yq is required to read $RECIPE" >&2; exit 1; }

list_commands() { yq -r '.required.commands[]' "$RECIPE"; }

case "${1:-list}" in
  list)
    printf '%-28s %-12s %s\n' CAPABILITY STATUS SOURCE
    printf '%-28s %-12s %s\n' '----------------------------' '------------' '------'
    while IFS= read -r tool; do
      if command -v "$tool" >/dev/null 2>&1; then status=INSTALLED; else status=MISSING; fi
      printf '%-28s %-12s %s\n' "$tool" "$status" "$RECIPE"
    done < <(list_commands)
    while IFS= read -r pkg; do
      if "$HOME/.local/share/cusimanse/venv/bin/python" -c "import importlib.util; raise SystemExit(0 if importlib.util.find_spec('${pkg//-/_}') else 1)" 2>/dev/null; then status=INSTALLED; else status=MISSING; fi
      printf '%-28s %-12s %s\n' "python:$pkg" "$status" "$RECIPE"
    done < <(yq -r '.required.python_packages[]' "$RECIPE")
    if [ -d "$HOME/.local/share/cusimanse/aegis/.git" ]; then status=INSTALLED; else status=MISSING; fi
    printf '%-28s %-12s %s\n' 'host:aegis' "$status" "$RECIPE"
    ;;
  config)
    printf 'Configuration directory: %s\n' "$CONFIG"
    for f in "$CONFIG"/*; do [ -e "$f" ] && printf '  %s\n' "$f"; done
    printf 'Aegis checkout: %s\n' "$HOME/.local/share/cusimanse/aegis/"
    printf 'Python environment: %s\n' "$HOME/.local/share/cusimanse/venv/"
    printf '\nSecrets are not printed. Source only the environment file you need:\n'
    printf '  source ~/.config/cusimanse/goose.env\n'
    printf '  source ~/.config/cusimanse/observability.env\n'
    printf '  source ~/.config/cusimanse/omniroute.env\n'
    ;;
  versions)
    while IFS= read -r tool; do
      if command -v "$tool" >/dev/null 2>&1; then
        printf '\n[%s]\n' "$tool"
        "$tool" --version 2>&1 | head -n 2 || "$tool" version 2>&1 | head -n 2 || true
      fi
    done < <(list_commands)
    ;;
  *) usage; exit 2;;
esac
