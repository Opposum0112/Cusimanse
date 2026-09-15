package capability

import (
	"context"

	"github.com/opposum0112/Cusimanse/internal/model"
)

type Capability interface {
	ID() string
	Describe() model.CapabilitySpec
	Check(context.Context, model.CapabilityRequest) error
	Execute(context.Context, model.CapabilityRequest) (Result, error)
}

type Result struct {
	Capability string
	Started    bool
	Completed  bool
	Message    string
}

type Registry struct {
	items map[string]Capability
}

func NewRegistry() *Registry { return &Registry{items: make(map[string]Capability)} }

func (r *Registry) Register(c Capability) error {
	if c == nil || c.ID() == "" {
		return ErrInvalidCapability
	}
	if _, ok := r.items[c.ID()]; ok {
		return ErrDuplicateCapability
	}
	r.items[c.ID()] = c
	return nil
}

func (r *Registry) Get(id string) (Capability, bool) {
	c, ok := r.items[id]
	return c, ok
}

func (r *Registry) IDs() []string {
	ids := make([]string, 0, len(r.items))
	for id := range r.items { ids = append(ids, id) }
	return ids
}
