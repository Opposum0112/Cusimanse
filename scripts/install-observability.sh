#!/usr/bin/env bash
set -euo pipefail
LOCAL_BIN="${HOME}/.local/bin"; mkdir -p "$LOCAL_BIN"; export PATH="$LOCAL_BIN:${GOBIN:-$HOME/go/bin}:$PATH"
log(){ printf '%s\n' "$*"; }; warn(){ printf 'Observability WARN: %s\n' "$*" >&2; }
asset_url(){
  local repo="$1"; python3 - "$repo" "$(uname -s)" "$(uname -m)" <<'PY'
import json,sys,urllib.request
repo,os,arch=sys.argv[1:]; os=os.lower(); arch={'x86_64':'amd64','aarch64':'arm64'}.get(arch,arch)
data=json.load(urllib.request.urlopen(f'https://api.github.com/repos/{repo}/releases/latest'))
for a in data.get('assets',[]):
    n=a['name'].lower()
    if os in n and arch in n and n.endswith(('.tar.gz','.tgz','.zip')):
        print(a['browser_download_url']); break
PY
}
install_numbat(){
  command -v numbat >/dev/null 2>&1 && { log 'Numbat: already installed'; return 0; }
  if command -v go >/dev/null 2>&1 && GOBIN="$LOCAL_BIN" go install github.com/perplexityai/numbat/cmd/numbat@latest; then log 'Numbat: installed via Go'; return 0; fi
  warn 'Numbat Go install failed; using official release fallback.'
  command -v curl >/dev/null 2>&1 || return 1; command -v python3 >/dev/null 2>&1 || return 1; command -v tar >/dev/null 2>&1 || return 1
  local url tmp binary; url="$(asset_url perplexityai/numbat)"; [ -n "$url" ] || return 1
  tmp="$(mktemp -d)"; curl -fL --retry 3 "$url" -o "$tmp/numbat.archive" || { rm -rf "$tmp"; return 1; }
  mkdir "$tmp/out"; case "$url" in *.zip) unzip -qo "$tmp/numbat.archive" -d "$tmp/out";; *) tar -xzf "$tmp/numbat.archive" -C "$tmp/out";; esac
  binary="$(find "$tmp/out" -type f -name numbat -print -quit)"; [ -n "$binary" ] || { rm -rf "$tmp"; return 1; }
  install -m 0755 "$binary" "$LOCAL_BIN/numbat"; rm -rf "$tmp"; command -v numbat >/dev/null 2>&1
}
install_aegis(){
  command -v aegis >/dev/null 2>&1 && { log 'Aegis: already installed'; return 0; }
  case "$(uname -s)" in Linux|Darwin) :;; *) warn 'Aegis native installer is unsupported here; use WSL2 on Windows'; return 1;; esac
  log 'Aegis: trying the verified upstream installer.'
  if curl -fsSL https://aegistraces.com/install | sh; then hash -r; command -v aegis >/dev/null 2>&1 && { log 'Aegis: installed'; return 0; }; fi
  warn 'Aegis upstream installer failed; using source/Docker fallback.'
  command -v git >/dev/null 2>&1 || return 1; command -v docker >/dev/null 2>&1 || { warn 'Docker required for Aegis source fallback'; return 1; }
  local dir="${HOME}/.local/share/cusimanse/aegis"; mkdir -p "$(dirname "$dir")"
  [ -d "$dir/.git" ] || git clone --depth 1 https://github.com/Justin0504/Aegis "$dir" || return 1
  (cd "$dir" && docker compose up -d) || return 1
  log 'Aegis: source/Docker fallback deployed'; return 0
}
install_numbat || warn 'Numbat: NOT_DEPLOYED'
install_aegis || warn 'Aegis: NOT_DEPLOYED'
