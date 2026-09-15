package capability

import (
	"context"
	"testing"

	"github.com/opposum0112/Cusimanse/internal/model"
)

type fake struct{}
func (fake) ID() string { return "fake" }
func (fake) Describe() model.CapabilitySpec { return model.CapabilitySpec{ID: "fake", Version: "1", Description: "test"} }
func (fake) Check(context.Context, model.CapabilityRequest) error { return nil }
func (fake) Execute(context.Context, model.CapabilityRequest) (Result, error) { return Result{Capability: "fake", Started: true, Completed: true}, nil }

func TestRegistryRejectsDuplicate(t *testing.T) {
	r := NewRegistry()
	if err := r.Register(fake{}); err != nil { t.Fatal(err) }
	if err := r.Register(fake{}); err != ErrDuplicateCapability { t.Fatalf("got %v", err) }
	if _, ok := r.Get("fake"); !ok { t.Fatal("registered capability not found") }
}
