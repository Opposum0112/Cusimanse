#!/usr/bin/env bash
# Hash a directory tree to manifests/evidence.sha256
hash_tree() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  (cd "$src" && find . -type f -print0 | sort -z | xargs -0 sha256sum) > "$dest"
  log "wrote $dest"
}
