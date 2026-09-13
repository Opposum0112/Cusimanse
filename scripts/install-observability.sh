#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN="${HOME}/.local/bin"; mkdir -p "$LOCAL_BIN"; export PATH="$LOCAL_BIN:${GOBIN:-$HOME/go/bin}:$PATH"
log(){ printf '%s\n' "$*"; }
warn(){ printf 'Observability WARN: %s\n' "$*" >&2; }
install_numbat(){
  if command -v numbat >/dev/null 2>&1; then log 'Numbat: already installed'; return 0; fi
  command -v go >/dev/null 2>&1 || { warn 'Go unavailable; Numbat: NOT_DEPLOYED'; return 1; }
  log 'Numbat: installing with Go first.'
  if GOBIN="$LOCAL_BIN" go install github.com/perplexityai/numbat/cmd/numbat@latest; then log 'Numbat: installed'; return 0; fi
  warn 'Numbat Go install failed; trying official release archive fallback.'
  local api tag os arch asset tmp
  api='https://api.github.com/repos/perplexityai/numbat/releases/latest'
  tag="$(curl -fsSL "$api" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')" || return 1
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"; arch="$(uname -m)"
  case "$arch" in x86_64|amd64) arch=x86_64;; aarch64|arm64) arch=arm64;; *) warn "unsupported architecture $arch"; return 1;; esac
  tmp="$(mktemp -d)"; asset="numbat-${tag#v}-${os}-${arch}.tar.gz"
  curl -fL --retry 3 "https://github.com/perplexityai/numbat/releases/download/${tag}/${asset}" -o "$tmp/numbat.tar.gz" || { rm -rf "$tmp"; return 1; }
  tar -xzf "$tmp/numbat.tar.gz" -C "$LOCAL_BIN"; rm -rf "$tmp"; chmod +x "$LOCAL_BIN/numbat"; command -v numbat >/dev/null 2>&1
}
install_aegis(){
  if command -v aegis >/dev/null 2>&1; then log 'Aegis: already installed'; return 0; fi
  log 'Aegis: using the verified upstream installer (Linux/macOS; Windows via WSL2).'
  if curl -fsSL https://aegistraces.com/install | sh; then hash -r; command -v aegis >/dev/null 2>&1 && { log 'Aegis: installed'; return 0; }; fi
  warn 'Aegis upstream installer failed; trying source fallback.'
  command -v git >/dev/null 2>&1 || return 1
  local dir="${HOME}/.local/share/cusimanse/aegis"
  if [ ! -d "$dir/.git" ]; then git clone --depth 1 https://github.com/Justin0504/Aegis "$dir" || return 1; fi
  if [ -f "$dir/Makefile" ] && command -v make >/dev/null 2>&1; then (cd "$dir" && make build) || return 1; fi
  [ -x "$dir/aegis" ] && install -m 0755 "$dir/aegis" "$LOCAL_BIN/aegis"
  command -v aegis >/dev/null 2>&1
}
install_numbat || warn 'Numbat: NOT_DEPLOYED'
install_aegis || warn 'Aegis: NOT_DEPLOYED'
