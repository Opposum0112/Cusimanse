package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/opposum0112/Cusimanse/internal/compiler"
)

func TestReferenceExperimentsCompile(t *testing.T) {
	root := filepath.Join("..", "..")
	for _, id := range []string{"npm-install-001", "npm-lifecycle-001", "npm-threat-001", "go-install-001"} {
		doc, err := compiler.LoadID(root, id)
		if err != nil {
			t.Fatalf("%s: %v", id, err)
		}
		if doc.Spec.Requirements.Workload == "" {
			t.Fatalf("%s missing workload", id)
		}
	}
}

func TestDeclarativeCatalogExists(t *testing.T) {
	root := filepath.Join("..", "..")
	for _, p := range []string{
		"schemas/cusimanse.yaml",
		"schemas/experiment.schema.json",
		"experiments/npm-install-001.yaml",
		"host-prep/default.yaml",
		"roles/bindings.yaml",
		"roles/skill-registry.yaml",
		"recipes/goose/session.yaml",
	} {
		if _, err := os.Stat(filepath.Join(root, p)); err != nil {
			t.Fatalf("missing %s", p)
		}
	}
}
