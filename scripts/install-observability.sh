#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN="${HOME}/.local/bin"
DATA_DIR="${HOME}/.local/share/cusimanse"
mkdir -p "$LOCAL_BIN" "$DATA_DIR"
export PATH="$LOCAL_BIN:${GOBIN:-$HOME/go/bin}:$PATH"
log(){ printf '%s\n' "$*"; }
warn(){ printf 'Observability WARN: %s\n' "$*" >&2; }

install_numbat(){
  command -v numbat >/dev/null 2>&1 && { log 'Numbat: already installed'; return 0; }
  if command -v go >/dev/null 2>&1 && GOBIN="$LOCAL_BIN" go install github.com/perplexityai/numbat/cmd/numbat@latest; then
    log 'Numbat: installed via Go'; return 0
  fi
  warn 'Numbat: Go installation unavailable; NOT_DEPLOYED'
  return 1
}

install_aegis(){
  command -v git >/dev/null 2>&1 || { warn 'Aegis: git unavailable'; return 1; }
  command -v npm >/dev/null 2>&1 || { warn 'Aegis: npm unavailable (Node.js 22+ required by upstream)'; return 1; }
  case "$(uname -s)" in Linux|Darwin) :;; *) warn 'Aegis: upstream source workflow is not declared for this host'; return 1;; esac
  local dir="$DATA_DIR/aegis"
  if [ ! -d "$dir/.git" ]; then
    git clone --depth 1 https://github.com/antropos17/Aegis "$dir" || return 1
  fi
  (cd "$dir" && npm install) || return 1
  log "Aegis: source checkout prepared at $dir"
  log 'Aegis: installed dependencies; observer launch remains a session/runtime action'
  return 0
}

install_numbat || true
install_aegis || true
log 'Observability installation complete; unavailable optional providers remain NOT_DEPLOYED.'
