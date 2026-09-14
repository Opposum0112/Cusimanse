#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$HOME/.local/bin"
CFG="$HOME/.config/cusimanse"
DATA="$HOME/.local/share/cusimanse"
mkdir -p "$BIN" "$CFG" "$DATA"
export PATH="$BIN:$HOME/go/bin:$PATH"
log(){ printf '[cusimanse] %s\n' "$*"; }
fail(){ printf '[cusimanse] ERROR: %s\n' "$*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
OS="$(uname -s)"; SUDO=""; [ "$(id -u)" -eq 0 ] || SUDO=sudo
if [ "$OS" = Darwin ]; then
  have brew || fail 'Homebrew is required on macOS'
  brew install git curl python node ruby go jq yq ripgrep qemu lima
elif [ "$OS" = Linux ]; then
  if have apt-get; then $SUDO apt-get update; $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y git bash curl python3 python3-pip ruby nodejs npm golang-go jq yq ripgrep qemu-system-x86 qemu-utils lima ca-certificates strace tcpdump iproute2 iputils-ping dnsutils lsof inotify-tools file psmisc procps
  elif have dnf; then $SUDO dnf install -y git bash curl python3 python3-pip ruby nodejs npm golang jq yq ripgrep qemu-system-x86-core qemu-img lima ca-certificates strace tcpdump iproute iputils bind-utils lsof inotify-tools file psmisc procps
  elif have pacman; then $SUDO pacman -Sy --needed --noconfirm git bash curl python python-pip ruby nodejs npm go jq yq ripgrep qemu lima strace tcpdump iproute iputils bind lsof inotify-tools file psmisc procps
  elif have zypper; then $SUDO zypper --non-interactive install git bash curl python3 python3-pip ruby nodejs npm go jq yq ripgrep qemu lima ca-certificates strace tcpdump iproute2 iputils bind-utils lsof inotify-tools file psmisc procps
  else fail 'No supported Linux package manager'; fi
else fail 'Use Linux, macOS, or WSL2'; fi

have limactl || fail 'Lima installation failed'
if ! have goose; then curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | CONFIGURE=false GOOSE_BIN_DIR="$BIN" bash; fi
have goose || fail 'Goose installation failed'
node_major="$(node -p 'process.versions.node.split(".")[0]')"; [ "$node_major" -ge 20 ] || fail 'Node.js 20+ is required'

python3 -m pip install --user --upgrade litellm arize-phoenix opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp
GOBIN="$BIN" go install github.com/perplexityai/numbat/cmd/numbat@latest
npm install -g omniroute
have numbat || fail 'Numbat installation failed'; have omniroute || fail 'OmniRoute installation failed'

AEGIS="$DATA/aegis"; if [ ! -d "$AEGIS/.git" ]; then git clone --depth 1 https://github.com/antropos17/Aegis "$AEGIS"; fi; (cd "$AEGIS" && npm ci)
cat > "$BIN/cusimanse-aegis" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$AEGIS"
npm start
EOF
chmod +x "$BIN/cusimanse-aegis"

# Mandatory local routing: Goose -> LiteLLM -> OmniRoute. Provider secrets are external.
cat > "$CFG/litellm.yaml" <<'EOF'
model_list:
  - model_name: auto
    litellm_params:
      model: openai/auto
      api_base: http://127.0.0.1:20128/v1
      api_key: os.environ/OMNIROUTE_API_KEY
router_settings:
  routing_strategy: simple-shuffle
  fallbacks: []
EOF
cat > "$CFG/omniroute.env" <<'EOF'
OMNIROUTE_HOST=127.0.0.1
OMNIROUTE_PORT=20128
EOF
cat > "$CFG/observability.env" <<EOF
NUMBAT_RECORD_FILE=$HOME/.numbat/cusimanse.ndjson
PHOENIX_HOST=127.0.0.1
PHOENIX_PORT=6006
OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318
AEGIS_ROOT=$AEGIS
EOF
cat > "$CFG/goose.env" <<'EOF'
export GOOSE_PROVIDER=openai
export OPENAI_HOST=http://127.0.0.1:4000
export OPENAI_API_KEY=${LITELLM_API_KEY:-}
export GOOSE_RECIPE_PATH="$PWD/recipes"
EOF

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do [ -f "$rc" ] && grep -Fq 'export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"' "$rc" || { [ -f "$rc" ] && printf '\nexport PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"\n' >> "$rc" || true; }; done
"$ROOT/preflight.sh"
log 'Host preparation PASS'
printf '%s\n' 'Next:' '  source ~/.config/cusimanse/goose.env' '  ./validate.sh' '  goose run --recipe ./recipes/go-install-001/recipe.yaml --interactive'
