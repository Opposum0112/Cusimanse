#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
BIN="$HOME/.local/bin"
DATA="$HOME/.local/share/cusimanse"
CFG="$HOME/.config/cusimanse"
mkdir -p "$BIN" "$DATA" "$CFG"

log(){ printf '[cusimanse] %s\n' "$*"; }
fail(){ printf '[cusimanse] ERROR: %s\n' "$*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
if [ "$OS" = Darwin ]; then
  have brew || fail 'Homebrew is required on macOS'
  brew install go jq yq ripgrep qemu lima ca-certificates
elif [ "$OS" = Linux ]; then
  SUDO=""; [ "$(id -u)" -eq 0 ] || SUDO=sudo
  if have apt-get; then
    "$SUDO" apt-get update
    "$SUDO" apt-get install -y git bash curl jq yq ripgrep ca-certificates qemu-system-x86 qemu-utils strace tcpdump iproute2 iputils-ping dnsutils lsof psmisc procps
  elif have dnf; then
    "$SUDO" dnf install -y git bash curl jq yq ripgrep ca-certificates qemu-system-x86-core qemu-img strace tcpdump iproute iputils bind-utils lsof psmisc procps
  elif have pacman; then
    "$SUDO" pacman -Sy --needed --noconfirm git bash curl jq yq ripgrep ca-certificates qemu strace tcpdump iproute iputils bind lsof psmisc procps
  elif have zypper; then
    "$SUDO" zypper --non-interactive install git bash curl jq yq ripgrep ca-certificates qemu strace tcpdump iproute2 iputils bind-utils lsof psmisc procps
  else
    fail 'unsupported Linux package manager'
  fi
else
  fail 'Use WSL2 or a supported macOS/Linux environment'
fi

# ADK Go v2.4.0 declares Go 1.26.6. Do not silently accept an older toolchain.
GO_VERSION="$(go env GOVERSION 2>/dev/null || true)"
[ -n "$GO_VERSION" ] || fail 'Go is not installed'
if [ "${GO_VERSION#go}" != "1.26.6" ]; then
  GO_MAJOR="$(printf '%s' "${GO_VERSION#go}" | cut -d. -f1)"
  GO_MINOR="$(printf '%s' "${GO_VERSION#go}" | cut -d. -f2)"
  [ "$GO_MAJOR" -gt 1 ] || [ "$GO_MINOR" -ge 26 ] || fail 'Go 1.26.6+ is required by ADK Go v2.4.0'
fi

cd "$ROOT"
go mod download
go test ./...

cat > "$BIN/cusimanse-agent" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$ROOT"
exec go run ./cmd/cusimanse-agent "\$@"
EOF
chmod +x "$BIN/cusimanse-agent"

cat > "$CFG/runtime.env.example" <<'EOF'
# Required for the initial ADK Gemini model adapter.
export GOOGLE_API_KEY=""
export CUSIMANSE_MODEL="gemini-2.5-flash"

# Durable Cusimanse execution envelope.
export CUSIMANSE_STATE_DIR=".cusimanse/state"
EOF

log 'Native Go + ADK Go 2 installation complete.'
log 'Set GOOGLE_API_KEY and run: cusimanse-agent'
