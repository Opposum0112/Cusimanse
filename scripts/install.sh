#!/usr/bin/env bash
# Idempotent host bootstrap. Reads host-prep/default.yaml when yq is present.
# Linux / macOS / Windows (Git Bash, MSYS, Cygwin). WSL2 uses Linux path.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/bin:$PATH"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"
log(){ printf '[cusimanse] %s\n' "$*"; }
warn(){ printf '[cusimanse] WARN: %s\n' "$*" >&2; }
fail(){ printf '[cusimanse] ERROR: %s\n' "$*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }

OS_RAW="$(uname -s 2>/dev/null || echo unknown)"
case "$OS_RAW" in
  Linux*) OS=linux ;;
  Darwin*) OS=macos ;;
  MINGW*|MSYS*|CYGWIN*|Windows*) OS=windows ;;
  *) OS=unknown ;;
esac

SUDO=""
if [ "$OS" != windows ] && [ "$(id -u 2>/dev/null || echo 1)" != 0 ]; then
  have sudo && SUDO=sudo
fi
run_root(){ if [ -n "$SUDO" ]; then $SUDO "$@"; else "$@"; fi; }

manager()
{
  case "$OS" in
    linux)
      have apt-get && { echo apt-get; return; }
      have dnf && { echo dnf; return; }
      have pacman && { echo pacman; return; }
      have zypper && { echo zypper; return; }
      have apk && { echo apk; return; }
      ;;
    macos)
      have brew && { echo brew; return; }
      ;;
    windows)
      have winget && { echo winget; return; }
      have scoop && { echo scoop; return; }
      have choco && { echo choco; return; }
      ;;
  esac
  echo none
}

pkg_install()
{
  local mgr pkgs
  mgr="$(manager)"
  pkgs="$*"
  [ -n "$pkgs" ] || return 1
  log "install via $mgr: $pkgs"
  case "$mgr" in
    apt-get) run_root apt-get update -y >/dev/null 2>&1 || true; run_root apt-get install -y $pkgs ;;
    dnf) run_root dnf install -y $pkgs ;;
    pacman) run_root pacman -Sy --needed --noconfirm $pkgs ;;
    zypper) run_root zypper --non-interactive install $pkgs ;;
    apk) run_root apk add --no-cache $pkgs ;;
    brew) brew install $pkgs ;;
    winget) winget install --accept-package-agreements --accept-source-agreements $pkgs ;;
    scoop) scoop install $pkgs ;;
    choco) choco install -y $pkgs ;;
    none) return 1 ;;
    *) return 1 ;;
  esac
}

install_yq_binary()
{
  have yq && return 0
  local ver=v4.44.3 arch url tmp
  arch="$(uname -m)"
  case "$OS-$arch" in
    linux-x86_64|linux-amd64) url="https://github.com/mikefarah/yq/releases/download/${ver}/yq_linux_amd64" ;;
    linux-aarch64|linux-arm64) url="https://github.com/mikefarah/yq/releases/download/${ver}/yq_linux_arm64" ;;
    macos-arm64) url="https://github.com/mikefarah/yq/releases/download/${ver}/yq_darwin_arm64" ;;
    macos-x86_64) url="https://github.com/mikefarah/yq/releases/download/${ver}/yq_darwin_amd64" ;;
    windows-*) url="https://github.com/mikefarah/yq/releases/download/${ver}/yq_windows_amd64.exe" ;;
    *) return 1 ;;
  esac
  tmp="$(mktemp)"
  curl -fsSL --retry 3 "$url" -o "$tmp" || return 1
  if [ "$OS" = windows ]; then
    mv "$tmp" "$BIN/yq.exe"
    chmod +x "$BIN/yq.exe"
  else
    mv "$tmp" "$BIN/yq"
    chmod +x "$BIN/yq"
  fi
}

ensure()
{
  local bin="$1" shift || true
  if have "$bin"; then
    log "ok $bin (already present)"
    return 0
  fi
  if pkg_install "$@"; then
    have "$bin" && { log "ok $bin"; return 0; }
  fi
  warn "package manager could not provide $bin; trying official binary if known"
  return 1
}

log "os=$OS manager=$(manager)"

# --- essential, skip if present ---
have git || ensure git git || warn "git missing"
have curl || ensure curl curl || fail "curl is required for fallback downloads"
have yq || pkg_install yq || install_yq_binary || warn "yq missing"
have go || pkg_install golang-go go golang || warn "go missing; install from https://go.dev/dl/"
have node || pkg_install nodejs node || warn "node missing; install LTS from https://nodejs.org"
have npm || warn "npm missing (comes with node)"

if ! have goose; then
  if have curl; then
    log "install goose via official CLI script"
    tmp="$(mktemp)"
    if curl -fsSL --retry 3 "https://github.com/block/goose/releases/download/stable/download_cli.sh" -o "$tmp" 2>/dev/null \
      || curl -fsSL --retry 3 "https://github.com/aaif-goose/goose/releases/latest/download/download_cli.sh" -o "$tmp" 2>/dev/null; then
      CONFIGURE=false GOOSE_BIN_DIR="$BIN" bash "$tmp" || warn "goose official installer failed"
    fi
    rm -f "$tmp"
  fi
  have goose || warn "goose missing; agent bootstrap cannot start until it is on PATH"
else
  log "ok goose (already present)"
fi

# compute — optional except we prefer one provider
if [ "$OS" = macos ] || [ "$OS" = linux ]; then
  have limactl || pkg_install lima || warn "lima NOT_DEPLOYED"
  have qemu-system-x86_64 || pkg_install qemu qemu-system-x86 || warn "qemu NOT_DEPLOYED"
fi
have multipass || pkg_install multipass Canonical.Multipass || warn "multipass NOT_DEPLOYED"

# optional observability / gateway — never fail the script
if have python3 || have python; then
  PY="$(command -v python3 || command -v python)"
  if ! have litellm; then "$PY" -m pip install --user litellm >/dev/null 2>&1 && log "ok litellm" || warn "litellm NOT_DEPLOYED"; else log "ok litellm"; fi
  if ! have clawmetry; then "$PY" -m pip install --user clawmetry >/dev/null 2>&1 && log "ok clawmetry" || warn "clawmetry NOT_DEPLOYED"; else log "ok clawmetry"; fi
fi
if have go && ! have numbat; then
  GOBIN="$BIN" go install github.com/perplexityai/numbat/cmd/numbat@latest >/dev/null 2>&1 && log "ok numbat" || warn "numbat NOT_DEPLOYED"
fi
if have npm && ! have omniroute; then
  npm install -g omniroute >/dev/null 2>&1 && log "ok omniroute" || warn "omniroute NOT_DEPLOYED"
fi

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ] && ! grep -Fq 'Cusimanse PATH' "$rc"; then
    printf '\n# Cusimanse PATH\nexport PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"\n' >> "$rc"
  fi
done

log "bootstrap complete (idempotent). Re-run anytime."
log "required next: goose on PATH, then go run ./cmd/compile host-prep npm-install-001"
