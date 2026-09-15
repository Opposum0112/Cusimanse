package main

import (
    "encoding/json"
    "os"
    "path/filepath"
    "strings"
    "testing"
)

func repoFile(t *testing.T, path string) string { t.Helper(); b,err:=os.ReadFile(filepath.Join("..","..",path));if err!=nil{t.Fatalf("read %s: %v",path,err)};return string(b) }
func TestCrossLayerNPMThreatReferences(t *testing.T){contract:=repoFile(t,"contracts/npm-threat-001.md");experiment:=repoFile(t,"recipes/experiments/npm-threat-001.yaml");recipe:=repoFile(t,"recipes/npm-threat-001/recipe.yaml");for _,m:=range []string{"authorization","native Go policy engine","disposable Lima","localhost"}{if !strings.Contains(strings.ToLower(contract),strings.ToLower(m)){t.Fatalf("contract missing %q",m)}};for _,m:=range []string{"contract: contracts/npm-threat-001.md","workload: npm-threat","network: localhost-only","enforcement: internal/policy","required_checks: [vm, network, mounts]"}{if !strings.Contains(experiment,m){t.Fatalf("experiment missing %q",m)}};if strings.Contains(experiment,"scripts/policyctl"){t.Fatal("experiment must not name a shell policy authority")};if !strings.Contains(recipe,"name: summon"){t.Fatal("reference Goose recipe must explicitly declare summon")};for _,p:=range []string{"recipes/subrecipes/evidence-analysis.yaml","recipes/subrecipes/verification.yaml","recipes/subrecipes/report.yaml"}{if _,err:=os.Stat(filepath.Join("..","..",p));err!=nil{t.Fatalf("recipe dependency missing: %s",p)}}}
func TestCrossLayerInventoriesArePresent(t *testing.T){for _,p:=range []string{"recipes/host/security-research.yaml","recipes/gateway/mandatory.yaml","recipes/observability/mandatory.yaml","recipes/session/learning-workflow.yaml","recipes/profiles/registry.yaml","recipes/agents/adapter-matrix.yaml","internal/policy/loader.go","internal/preflight/preflight.go","internal/validation/validation.go"}{if _,err:=os.Stat(filepath.Join("..","..",p));err!=nil{t.Fatalf("inventory/runtime package missing: %s",p)}}}
func TestManifestRemainsValid(t *testing.T){var m map[string]any;if err:=json.Unmarshal([]byte(repoFile(t,"manifest/PACKAGE-MANIFEST.json")),&m);err!=nil{t.Fatalf("manifest is not valid JSON: %v",err)};if m["reference_operator"]!="goose"{t.Fatalf("reference operator = %v, want goose",m["reference_operator"])}}
