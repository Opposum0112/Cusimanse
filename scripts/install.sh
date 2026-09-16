#!/usr/bin/env bash
# Idempotent host bootstrap for the Goose-native Cusimanse researcher workflow.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/bin:$PATH"
BIN="$HOME/.local/bin"; mkdir -p "$BIN"
log(){ printf '[cusimanse] %s\n' "$*"; }; warn(){ printf '[cusimanse] WARN: %s\n' "$*" >&2; }; fail(){ printf '[cusimanse] ERROR: %s\n' "$*" >&2; exit 1; }; have(){ command -v "$1" >/dev/null 2>&1; }
OS_RAW="$(uname -s 2>/dev/null || echo unknown)"; case "$OS_RAW" in Linux*) OS=linux;; Darwin*) OS=macos;; MINGW*|MSYS*|CYGWIN*|Windows*) OS=windows;; *) OS=unknown;; esac
SUDO=""; if [ "$OS" != windows ] && [ "$(id -u 2>/dev/null || echo 1)" != 0 ]; then have sudo && SUDO=sudo; fi
run_root(){ if [ -n "$SUDO" ]; then $SUDO "$@"; else "$@"; fi; }
manager(){ case "$OS" in linux) for m in apt-get dnf pacman zypper apk; do have "$m" && { echo "$m"; return; }; done;; macos) have brew && { echo brew; return; };; windows) for m in winget scoop choco; do have "$m" && { echo "$m"; return; }; done;; esac; echo none; }
pkg_install(){ local mgr; mgr="$(manager)"; [ "$mgr" != none ] || return 1; log "install via $mgr: $*"; case "$mgr" in apt-get) run_root apt-get update -y >/dev/null 2>&1 || true; run_root apt-get install -y "$@";; dnf) run_root dnf install -y "$@";; pacman) run_root pacman -Sy --needed --noconfirm "$@";; zypper) run_root zypper --non-interactive install "$@";; apk) run_root apk add --no-cache "$@";; brew) brew install "$@";; winget) winget install --accept-package-agreements --accept-source-agreements "$@";; scoop) scoop install "$@";; choco) choco install -y "$@";; esac; }
log "os=$OS manager=$(manager)"
have git || pkg_install git || warn 'git NOT_DEPLOYED'
have curl || pkg_install curl || fail 'curl is required'
have yq || pkg_install yq || warn 'yq NOT_DEPLOYED'
have go || pkg_install golang-go go golang || warn 'go NOT_DEPLOYED'
have node || pkg_install nodejs node || warn 'node NOT_DEPLOYED'
have npm || warn 'npm NOT_DEPLOYED'
if ! have goose && have curl; then tmp="$(mktemp)"; if curl -fsSL --retry 3 "https://github.com/block/goose/releases/download/stable/download_cli.sh" -o "$tmp" 2>/dev/null || curl -fsSL --retry 3 "https://github.com/aaif-goose/goose/releases/latest/download/download_cli.sh" -o "$tmp" 2>/dev/null; then CONFIGURE=false GOOSE_BIN_DIR="$BIN" bash "$tmp" || true; fi; rm -f "$tmp"; fi
have goose || warn 'goose NOT_DEPLOYED'
if [ "$OS" = macos ] || [ "$OS" = linux ]; then have limactl || pkg_install lima || warn 'lima NOT_DEPLOYED'; have qemu-system-x86_64 || pkg_install qemu qemu-system-x86 || warn 'qemu NOT_DEPLOYED'; fi
have multipass || pkg_install multipass Canonical.Multipass || warn 'multipass NOT_DEPLOYED'
if have python3 || have python; then PY="$(command -v python3 || command -v python)"; have litellm || "$PY" -m pip install --user litellm >/dev/null 2>&1 || warn 'litellm NOT_DEPLOYED'; have clawmetry || "$PY" -m pip install --user clawmetry >/dev/null 2>&1 || warn 'clawmetry NOT_DEPLOYED'; fi
if have go && ! have numbat; then GOBIN="$BIN" go install github.com/perplexityai/numbat/cmd/numbat@latest >/dev/null 2>&1 || warn 'numbat NOT_DEPLOYED'; fi
if have npm && ! have omniroute; then npm install -g omniroute >/dev/null 2>&1 || warn 'omniroute NOT_DEPLOYED'; fi
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do if [ -f "$rc" ] && ! grep -Fq 'Cusimanse PATH' "$rc"; then printf '\n# Cusimanse PATH\nexport PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"\n' >> "$rc"; fi; done
log 'bootstrap complete (idempotent).'
log 'next: run cusimanse capability list, then goose recipe validate recipes/goose/session.yaml'
