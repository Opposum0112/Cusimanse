# Cusimanse Researcher Guide

Companion to the root README. Stay on `goose-native`. Do not merge other branches into this worktree for this workflow.

## 1. Bootstrap

```bash
git clone https://github.com/Opposum0112/Cusimanse.git
cd Cusimanse
git checkout goose-native
./scripts/install.sh
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
go run ./cmd/cusimanse doctor
```

## 2. Read the npm-install-001 set

```text
experiments/npm-install-001.yaml              LinkML contract values
recipes/experiments/npm-install-001.yaml      runtime requirements
recipes/npm-install-001/recipe.yaml           Goose recipe
recipes/goose/session.yaml                    generic Goose session
schemas/cusimanse.yaml                        schema
```

## 3. Validate

```bash
go run ./cmd/cusimanse validate
go run ./cmd/cusimanse preflight
go run ./cmd/cusimanse policy validate
go test ./...
bash ./scripts/tests/integration.sh
```

## 4. Validate Goose recipes

```bash
goose recipe validate recipes/goose/session.yaml
goose recipe validate recipes/npm-install-001/recipe.yaml
goose recipe validate recipes/subrecipes/evidence-analysis.yaml
goose recipe validate recipes/subrecipes/verification.yaml
goose recipe validate recipes/subrecipes/report.yaml
goose run --recipe ./recipes/npm-install-001/recipe.yaml --interactive
```

## 5. Resolve, approve, run

```bash
go run ./cmd/cusimanse resolve npm-install-001
SESSION_ID="npm-install-$(date +%Y%m%d-%H%M%S)"
go run ./cmd/cusimanse --approved run npm-install-001 "$SESSION_ID"
```

## 6. Read research artifacts

```bash
find "runs/$SESSION_ID" -maxdepth 3 -type f | sort
cat "runs/$SESSION_ID/verification/result.md"
cat "runs/$SESSION_ID/research-report/report.md"
go run ./cmd/cusimanse observability report "$SESSION_ID"
```

Raw evidence is distinct from model analysis. Preserve and hash before destroy.
