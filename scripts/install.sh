#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

printf '%s\n' 'AI Security Lab — host bootstrap'

if ! command -v python3 >/dev/null 2>&1; then
  echo 'python3 is required before labctl can run.' >&2
  exit 2
fi

# Host preflight is deliberately first. It is read-only.
"$ROOT/scripts/bin/labctl" preflight

install_linux() {
  command -v apt-get >/dev/null 2>&1 || {
    echo 'No supported Linux package manager found; prerequisites are NOT_DEPLOYED.' >&2
    return 2
  }
  if [ "$(id -u)" -ne 0 ]; then SUDO=sudo; else SUDO=; fi
  $SUDO apt-get update
  $SUDO apt-get install -y qemu-system-x86 qemu-utils python3 python3-venv curl git
  if ! command -v limactl >/dev/null 2>&1; then
    if apt-cache show lima >/dev/null 2>&1; then
      $SUDO apt-get install -y lima
    else
      echo 'Lima is not available from this apt repository. Install Lima using the platform package manager, then rerun this script.' >&2
      return 2
    fi
  fi
}

install_macos() {
  command -v brew >/dev/null 2>&1 || { echo 'Homebrew is required on macOS.' >&2; return 2; }
  brew install lima qemu python3 git
}

case "$(uname -s)" in
  Linux) install_linux ;;
  Darwin) install_macos ;;
  *) echo "Unsupported host OS: $(uname -s)" >&2; exit 2 ;;
esac

"$ROOT/scripts/bin/labctl" preflight
"$ROOT/scripts/bin/labctl" --dry-run init
cat <<'EOF'

Prerequisites are installed and the deployment plan was generated.
Review it, then run:
  ./scripts/bin/labctl init --apply
EOF
