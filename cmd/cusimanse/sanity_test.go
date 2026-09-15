package main

import (
    "encoding/json"
    "os"
    "path/filepath"
    "strings"
    "testing"
)

func repoFile(t *testing.T, path string) string {
    t.Helper()
    b, err := os.ReadFile(filepath.Join("..", "..", path))
    if err != nil { t.Fatalf("read %s: %v", path, err) }
    return string(b)
}

func TestCrossLayerNPMThreatReferences(t *testing.T) {
    contract := repoFile(t, "contracts/npm-threat-001.md")
    experiment := repoFile(t, "recipes/experiments/npm-threat-001.yaml")
    recipe := repoFile(t, "recipes/npm-threat-001/recipe.yaml")
    for _, marker := range []string{"authorization", "policyctl", "disposable Lima", "localhost"} {
        if !strings.Contains(strings.ToLower(contract), strings.ToLower(marker)) { t.Fatalf("contract missing %q", marker) }
    }
    for _, marker := range []string{"contract: contracts/npm-threat-001.md", "workload: npm-threat", "network: localhost-only", "required_checks: [vm, network, mounts]"} {
        if !strings.Contains(experiment, marker) { t.Fatalf("experiment missing %q", marker) }
    }
    if !strings.Contains(recipe, "name: summon") { t.Fatal("reference Goose recipe must explicitly declare summon") }
    for _, path := range []string{"recipes/subrecipes/evidence-analysis.yaml", "recipes/subrecipes/verification.yaml", "recipes/subrecipes/report.yaml"} {
        if _, err := os.Stat(filepath.Join("..", "..", path)); err != nil { t.Fatalf("recipe dependency missing: %s", path) }
    }
}

func TestCrossLayerInventoriesArePresent(t *testing.T) {
    for _, path := range []string{
        "recipes/host/security-research.yaml",
        "recipes/gateway/mandatory.yaml",
        "recipes/observability/mandatory.yaml",
        "recipes/session/learning-workflow.yaml",
        "recipes/profiles/registry.yaml",
        "recipes/agents/adapter-matrix.yaml",
    } {
        if _, err := os.Stat(filepath.Join("..", "..", path)); err != nil { t.Fatalf("inventory/recipe missing: %s", path) }
    }
}

func TestManifestRemainsValid(t *testing.T) {
    var manifest map[string]any
    if err := json.Unmarshal([]byte(repoFile(t, "manifest/PACKAGE-MANIFEST.json")), &manifest); err != nil { t.Fatalf("manifest is not valid JSON: %v", err) }
    if manifest["reference_operator"] != "goose" { t.Fatalf("reference operator = %v, want goose", manifest["reference_operator"]) }
}
