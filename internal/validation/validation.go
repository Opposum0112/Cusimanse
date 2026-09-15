package validation

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/opposum0112/Cusimanse/internal/compiler"
)

type Validator struct{ Root string }

func New(root string) Validator { return Validator{Root: root} }

func (v Validator) Project() error {
	_, err := compiler.LoadCatalog(v.Root)
	if err != nil {
		return fmt.Errorf("compiler catalog: %w", err)
	}
	return nil
}

func (v Validator) NoMarker(marker string, paths ...string) error {
	for _, root := range paths {
		matches, err := filepath.Glob(filepath.Join(v.Root, root))
		if err != nil {
			return err
		}
		for _, m := range matches {
			st, err := os.Stat(m)
			if err != nil || st.IsDir() {
				continue
			}
			b, err := os.ReadFile(m)
			if err != nil {
				return err
			}
			if strings.Contains(string(b), marker) {
				return fmt.Errorf("forbidden marker %q found in %s", marker, m)
			}
		}
	}
	return nil
}
