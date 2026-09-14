#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
RECIPE="$ROOT/recipes/host/security-research.yaml"
CONFIG="$HOME/.config/cusimanse"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/tools.sh list       List every host tool declared by the host recipe and its status.
  ./scripts/tools.sh config     Show non-secret Cusimanse configuration files and environment files.
  ./scripts/tools.sh versions   Show versions/identity for installed commands.
EOF
}

[ -f "$RECIPE" ] || { echo "Missing host recipe: $RECIPE" >&2; exit 1; }
command -v yq >/dev/null 2>&1 || { echo "yq is required to read $RECIPE" >&2; exit 1; }

case "${1:-list}" in
  list)
    printf '%-22s %-10s %s\n' TOOL STATUS SOURCE
    printf '%-22s %-10s %s\n' '----------------------' '----------' '------'
    while IFS= read -r tool; do
      if command -v "$tool" >/dev/null 2>&1; then status=INSTALLED; else status=MISSING; fi
      printf '%-22s %-10s %s\n' "$tool" "$status" "$RECIPE"
    done < <(yq -r '.required | to_entries[] | .value[]' "$RECIPE" | sort -u)
    ;;
  config)
    printf 'Configuration directory: %s\n' "$CONFIG"
    for f in "$CONFIG"/*; do
      [ -e "$f" ] || continue
      printf '  %s\n' "$f"
    done
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
    done < <(yq -r '.required | to_entries[] | .value[]' "$RECIPE" | sort -u)
    ;;
  *) usage; exit 2;;
esac
