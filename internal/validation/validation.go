package validation

import (
	"fmt"

	"github.com/opposum0112/Cusimanse/internal/compiler"
)

type Validator struct{ Root string }

func New(root string) Validator { return Validator{Root: root} }

// Project now validates the Goose-native catalog, not markdown contracts.
func (v Validator) Project() error {
	_, err := compiler.LoadCatalog(v.Root)
	if err != nil {
		return fmt.Errorf("compiler catalog: %w", err)
	}
	return nil
}
