#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
while IFS= read -r -d '' f; do
  ruby -e 'require "yaml"; YAML.load_file(ARGV[0]); puts "OK #{ARGV[0]}"' "$f"
done < <(find "$ROOT/recipes" -type f -name '*.yaml' -print0)
while IFS= read -r -d '' f; do bash -n "$f"; done < <(find "$ROOT/scripts" -type f -name '*.sh' -print0)
