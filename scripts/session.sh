#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
usage(){ echo "usage: $0 create <experiment-id> <agent> [session-id] | checkpoint <session-id> <state> | hash <session-id> | verify-layout <session-id>"; }
[ "$#" -ge 1 ] || { usage; exit 2; }
command -v yq >/dev/null 2>&1 || { echo 'session: yq is required' >&2; exit 1; }
create(){
  local experiment="$1" agent="$2" sid="${3:-$(date -u +%Y%m%dT%H%M%SZ)-${experiment}}" dir="runs/$sid"
  mkdir -p "$dir"/evidence/audit "$dir"/{provenance,analysis,verification,research-report,preservation,observability,learning/{candidates,evaluations,replays,verification,promotions}}
  cat > "$dir/session.yaml" <<EOF
session_id: $sid
experiment_id: $experiment
contract_ref: contracts/$experiment.md
recipe_ref: recipes/$experiment/recipe.yaml
state_contract: recipes/session/session-state.yaml
selected_primary_agent: $agent
state: CREATED
stage_history: []
EOF
  printf '%s\n' "created $dir/session.yaml"
  printf '%s\n' '{"event":"session_created","state":"CREATED"}' > "$dir/evidence/audit/events.jsonl"
  printf '%s\n' "$sid"
}
checkpoint(){
  local sid="$1" state="$2" file="runs/$sid/session.yaml"
  [ -f "$file" ] || { echo "session not found: $sid" >&2; exit 1; }
  yq -i ".state = \"$state\" | .stage_history += [{\"state\": \"$state\", \"timestamp_utc\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}]" "$file"
  printf '%s\n' "{\"event\":\"checkpoint\",\"state\":\"$state\"}" >> "runs/$sid/evidence/audit/events.jsonl"
}
hash(){
  local sid="$1" dir="runs/$sid"
  [ -d "$dir" ] || { echo "session not found: $sid" >&2; exit 1; }
  (cd "$dir" && find evidence -type f ! -path 'evidence/audit/manifest.sha256' -print0 | sort -z | xargs -0 sha256sum > evidence/audit/manifest.sha256)
  (cd "$dir" && find . -type f ! -path './evidence/audit/manifest.sha256' -print0 | sort -z | xargs -0 sha256sum > provenance/manifest.sha256)
}
verify_layout(){
  local sid="$1" dir="runs/$sid"
  for f in session.yaml evidence/audit/events.jsonl evidence/audit/manifest.sha256 evidence/index.yaml provenance/manifest.sha256 analysis/summary.md verification/result.md research-report/report.md research-report/report.yaml preservation/manifest.yaml observability/token-usage.yaml observability/dashboard.yaml; do [ -e "$dir/$f" ] || { echo "missing artifact: $dir/$f" >&2; exit 1; }; done
  echo 'SESSION ARTIFACT LAYOUT PASS'
}
case "$1" in
  create) [ "$#" -ge 3 ] || { usage; exit 2; }; create "$2" "$3" "${4:-}" ;;
  checkpoint) [ "$#" -eq 3 ] || { usage; exit 2; }; checkpoint "$2" "$3" ;;
  hash) [ "$#" -eq 2 ] || { usage; exit 2; }; hash "$2" ;;
  verify-layout) [ "$#" -eq 2 ] || { usage; exit 2; }; verify_layout "$2" ;;
  *) usage; exit 2;;
esac
