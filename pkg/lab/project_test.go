package lab

import (
	"os"
	"path/filepath"
	"testing"
)

func TestValidateProject(t *testing.T) {
	root := t.TempDir()
	for _, relative := range RequiredProjectPaths {
		path := filepath.Join(root, relative)
		if filepath.Ext(relative) == "" {
			if err := os.MkdirAll(path, 0o755); err != nil {
				t.Fatal(err)
			}
			continue
		}
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte("test"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	if err := ValidateProject(root); err != nil {
		t.Fatalf("expected valid project: %v", err)
	}
}

func TestValidateProjectRejectsMissingContract(t *testing.T) {
	root := t.TempDir()
	if err := ValidateProject(root); err == nil {
		t.Fatal("expected missing contract error")
	}
}
