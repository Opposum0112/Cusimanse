#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
usage(){ echo "usage: $0 create <experiment-id> <agent> [session-id] | checkpoint <session-id> <state> | hash <session-id> | verify-layout <session-id>"; }
[ "$#" -ge 1 ] || { usage; exit 2; }
command -v yq >/dev/null 2>&1 || { echo 'session: yq is required' >&2; exit 1; }
hash_cmd(){ if command -v sha256sum >/dev/null 2>&1; then echo sha256sum; elif command -v shasum >/dev/null 2>&1; then echo 'shasum -a 256'; else echo ''; fi; }
create(){
  local experiment="$1" agent="$2" sid dir
  sid="${3:-$(date -u +%Y%m%dT%H%M%SZ)-${experiment}}"
  dir="runs/$sid"
  [ ! -e "$dir" ] || { echo "session already exists: $sid" >&2; exit 1; }
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
learning:
  enabled: false
EOF
  printf '%s\n' '{"event":"session_created","state":"CREATED"}' > "$dir/evidence/audit/events.jsonl"
  printf '%s\n' 'status: NOT_STARTED' > "$dir/evidence/index.yaml"
  printf '%s\n' '# Analysis Summary' 'status: NOT_STARTED' > "$dir/analysis/summary.md"
  printf '%s\n' '# Verification Result' 'status: NOT_STARTED' > "$dir/verification/result.md"
  printf '%s\n' '# Research Report' 'status: NOT_STARTED' > "$dir/research-report/report.md"
  printf '%s\n' 'status: NOT_STARTED' > "$dir/research-report/report.yaml"
  printf '%s\n' 'status: NOT_STARTED' > "$dir/observability/token-usage.yaml"
  printf '%s\n' 'status: NOT_STARTED' > "$dir/observability/dashboard.yaml"
  printf '%s\n' 'status: NOT_PRESERVED' > "$dir/preservation/manifest.yaml"
  printf '%s\n' "created $dir/session.yaml" "$sid"
}
checkpoint(){
  local sid next file current allowed
  sid="$1"
  next="$2"
  file="runs/$sid/session.yaml"
  [ -f "$file" ] || { echo "session not found: $sid" >&2; exit 1; }
  current="$(yq -r '.state' "$file")"
  case "$current:$next" in
    CREATED:VALIDATED|VALIDATED:PREFLIGHTED|PREFLIGHTED:PLANNED|PLANNED:AWAITING_APPROVAL|AWAITING_APPROVAL:APPROVED|APPROVED:PROVISIONED|PROVISIONED:INSTRUMENTED|INSTRUMENTED:EXECUTING|EXECUTING:EVIDENCE_COLLECTED|EVIDENCE_COLLECTED:ANALYZING|ANALYZING:VERIFYING|VERIFYING:REPORTED|REPORTED:PRESERVED|PRESERVED:DESTROYED|DESTROYED:COMPLETE|*:PARTIAL|*:FAILED) allowed=1;;
    *) allowed=0;;
  esac
  [ "$allowed" = 1 ] || { echo "invalid lifecycle transition: $current -> $next" >&2; exit 1; }
  yq -y -i ".state = \"$next\" | .stage_history += [{\"state\": \"$next\", \"timestamp_utc\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}]" "$file"
  printf '%s\n' "{\"event\":\"checkpoint\",\"from\":\"$current\",\"state\":\"$next\"}" >> "runs/$sid/evidence/audit/events.jsonl"
}
hash(){
  local sid="$1" dir h
  dir="runs/$sid"
  [ -d "$dir" ] || { echo "session not found: $sid" >&2; exit 1; }
  h="$(hash_cmd)"; [ -n "$h" ] || { echo 'session: sha256 implementation unavailable' >&2; exit 1; }
  (cd "$dir" && find evidence -type f ! -path 'evidence/audit/manifest.sha256' -print0 | sort -z | while IFS= read -r -d '' f; do eval "$h \"$f\""; done > evidence/audit/manifest.sha256)
  (cd "$dir" && find . -type f ! -path './provenance/manifest.sha256' -print0 | sort -z | while IFS= read -r -d '' f; do eval "$h \"$f\""; done > provenance/manifest.sha256)
}
verify_layout(){
  local sid="$1" dir
  dir="runs/$sid"
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
