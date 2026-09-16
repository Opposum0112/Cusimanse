package validation

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type Validator struct{ Root string }

func New(root string) Validator { return Validator{Root: root} }

var requiredProjectFiles = []string{
	"schemas/cusimanse.yaml",
	"schemas/experiment.schema.json",
	"experiments/npm-install-001.yaml",
	"experiments/npm-lifecycle-001.yaml",
	"experiments/npm-threat-001.yaml",
	"experiments/go-install-001.yaml",
	"recipes/experiments/npm-install-001.yaml",
	"recipes/experiments/npm-lifecycle-001.yaml",
	"recipes/experiments/npm-threat-001.yaml",
	"recipes/experiments/go-install-001.yaml",
	"recipes/npm-install-001/recipe.yaml",
	"recipes/goose/session.yaml",
	"recipes/subrecipes/evidence-analysis.yaml",
	"recipes/subrecipes/verification.yaml",
	"recipes/subrecipes/report.yaml",
	"recipes/profiles/registry.yaml",
	"host-prep/default.yaml",
	"policies/host-policy.yaml",
	"cmd/cusimanse/main.go",
}

var forbiddenStaleMarkers = []string{
	"go run ./cmd/compile",
	"./cmd/compile",
	"cusimanse compile",
}

func (v Validator) Project() error {
	for _, rel := range requiredProjectFiles {
		if _, err := os.Stat(filepath.Join(v.Root, rel)); err != nil {
			return fmt.Errorf("missing required project file %s", rel)
		}
	}
	return v.NoMarkerList(forbiddenStaleMarkers, "README.md", "contracts", "recipes/goose", "cmd", "scripts/tests")
}

func (v Validator) NoMarker(marker string, paths ...string) error {
	return v.NoMarkerList([]string{marker}, paths...)
}

func (v Validator) NoMarkerList(markers []string, paths ...string) error {
	for _, root := range paths {
		matches, err := filepath.Glob(filepath.Join(v.Root, root))
		if err != nil {
			return err
		}
		if info, err := os.Stat(filepath.Join(v.Root, root)); err == nil && info.IsDir() {
			err := filepath.Walk(filepath.Join(v.Root, root), func(path string, info os.FileInfo, err error) error {
				if err != nil || info.IsDir() {
					return err
				}
				return v.scanFile(path, markers)
			})
			if err != nil {
				return err
			}
			continue
		}
		for _, m := range matches {
			if err := v.scanFile(m, markers); err != nil {
				return err
			}
		}
	}
	return nil
}

func (v Validator) scanFile(path string, markers []string) error {
	st, err := os.Stat(path)
	if err != nil || st.IsDir() {
		return nil
	}
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	text := string(b)
	for _, marker := range markers {
		if marker != "" && strings.Contains(text, marker) {
			return fmt.Errorf("forbidden marker %q found in %s", marker, path)
		}
	}
	return nil
}
