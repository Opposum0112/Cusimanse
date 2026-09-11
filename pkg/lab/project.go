package lab

import (
	"fmt"
	"os"
	"path/filepath"
)

// RequiredProjectPaths are the minimum contract files/directories needed by the
// deterministic Go control-plane bootstrap. Runtime-specific capabilities are
// deliberately not required here; those are checked by backends at execution time.
var RequiredProjectPaths = []string{
	"01-deployment-architecture.md",
	"02-system-requirements.md",
	"AGENTS.md",
	"recipes/goose/project.yaml",
	"recipes/goose/go-control-plane.yaml",
	"recipes/install/install-all.yaml",
	"recipes/stages/stage-map.yaml",
	"recipes/workloads",
	"recipes/lima/profiles",
	"recipes/instrumentation",
	"recipes/agent-monitoring",
}

// ValidateProject checks the repository-level contract without executing a
// workload, installing software, or starting a VM.
func ValidateProject(root string) error {
	if root == "" {
		return fmt.Errorf("project root is empty")
	}
	for _, relative := range RequiredProjectPaths {
		path := filepath.Join(root, relative)
		if _, err := os.Stat(path); err != nil {
			return fmt.Errorf("required project path %q: %w", relative, err)
		}
	}
	return nil
}

// SelfTest validates the Go control-plane bootstrap against the supplied root.
func SelfTest(root string) error {
	return ValidateProject(root)
}
