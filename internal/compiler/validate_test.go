package compiler

import (
	"path/filepath"
	"testing"
)

func repoRoot(t *testing.T) string {
	t.Helper()
	root, err := filepath.Abs("../..")
	if err != nil {
		t.fatal(err)
	}
	return root
}

func TestLoadReferenceExperiments(t *testing.T) {
	root := repoRoot(t)
	for _, id := range []string{"npm-install-001", "npm-lifecycle-001", "npm-threat-001", "go-install-001"} {
		doc, err := LoadID(root, id)
		if err != nil {
			t.Fatalf("%s: %v", id, err)
		}
		res := doc.Resolve()
		if res.Handler != doc.Spec.Requirements.Workload {
			t.Fatalf("%s handler mismatch", id)
		}
	}
}

func TestRejectsUnknownWorkload(t *testing.T) {
	doc := ExperimentDoc{
		APIVersion: "cusimanse.dev/v1",
		Kind:       "Experiment",
		Metadata:   Metadata{ID: "x", Title: "x"},
		Spec: Spec{
			Question:     "enough text for a question",
			HostPrep:     "none",
			Roles:        []string{"operator"},
			Scope:        Scope{Exclude: []string{"host-execution"}},
			Requirements: Requirements{Execution: "disposable", OS: "linux", Workload: "npm-hack", Network: "none", Instrumentation: []string{"process"}},
			PolicyChecks: []string{"vm"},
			Acceptance:   []string{"none"},
			Operator:     "cli",
		},
	}
	if err := doc.Validate(); err == nil {
		t.Fatal("expected unknown workload to fail")
	}
}
