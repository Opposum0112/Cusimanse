#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
while IFS= read -r -d '' f; do
  ruby -rdate -e 'require "yaml"; YAML.safe_load(File.read(ARGV[0]), permitted_classes: [Date, Time], aliases: true); puts "OK #{ARGV[0]}"' "$f"
done < <(find "$ROOT/recipes" -type f -name '*.yaml' -print0)
while IFS= read -r -d '' f; do bash -n "$f"; done < <(find "$ROOT/scripts" -type f -name '*.sh' -print0)
