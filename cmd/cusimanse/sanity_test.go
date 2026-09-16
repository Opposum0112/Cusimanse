package main

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/opposum0112/Cusimanse/internal/validation"
)

func TestReferenceExperimentsResolve(t *testing.T) {
	root := repoRoot(t)
	if _, err := exec.LookPath("yq"); err != nil {
		t.Skip("yq is required for resolve")
	}
	ctx := context.Background()
	for _, id := range []string{"npm-install-001", "npm-lifecycle-001", "npm-threat-001", "go-install-001"} {
		host, workload, err := resolve(ctx, root, id)
		if err != nil {
			t.Fatalf("%s: %v", id, err)
		}
		if host == "" || workload == "" {
			t.Fatalf("%s resolved empty profiles", id)
		}
	}
}

func TestDeclarativeCatalogExists(t *testing.T) {
	root := repoRoot(t)
	for _, p := range []string{
		"schemas/cusimanse.yaml",
		"schemas/experiment.schema.json",
		"experiments/npm-install-001.yaml",
		"recipes/experiments/npm-install-001.yaml",
		"recipes/npm-install-001/recipe.yaml",
		"recipes/goose/session.yaml",
		"host-prep/default.yaml",
		"roles/bindings.yaml",
		"roles/skill-registry.yaml",
		"cmd/cusimanse/main.go",
	} {
		if _, err := os.Stat(filepath.Join(root, p)); err != nil {
			t.Fatalf("missing %s", p)
		}
	}
}

func TestProjectValidationRejectsMissingCatalog(t *testing.T) {
	root := repoRoot(t)
	if err := validation.New(root).Project(); err != nil {
		t.Fatalf("project validation: %v", err)
	}
}

func repoRoot(t *testing.T) string {
	t.Helper()
	root := filepath.Join("..", "..")
	if _, err := os.Stat(filepath.Join(root, "go.mod")); err != nil {
		t.Fatal(err)
	}
	abs, err := filepath.Abs(root)
	if err != nil {
		t.Fatal(err)
	}
	return abs
}
