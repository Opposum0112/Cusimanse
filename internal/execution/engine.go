package execution

import (
	"context"
	"fmt"

	"github.com/opposum0112/Cusimanse/internal/capability"
	"github.com/opposum0112/Cusimanse/internal/model"
	"github.com/opposum0112/Cusimanse/internal/policy"
)

type Engine struct {
	Capabilities *capability.Registry
	Policy       *policy.Engine
}

func NewEngine(registry *capability.Registry, policyEngine *policy.Engine) *Engine {
	return &Engine{Capabilities: registry, Policy: policyEngine}
}

func (e *Engine) Execute(ctx context.Context, plan ExecutionPlan, capabilityID string, approved bool) (capability.Result, error) {
	if e == nil || e.Capabilities == nil || e.Policy == nil { return capability.Result{}, fmt.Errorf("runtime engine is not initialized") }
	decision := e.Policy.Evaluate(capabilityID, approved)
	if decision.Decision != model.PolicyAllow { return capability.Result{}, fmt.Errorf("capability %s blocked: %s", capabilityID, decision.Reason) }
	c, ok := e.Capabilities.Get(capabilityID)
	if !ok { return capability.Result{}, fmt.Errorf("capability %s is not registered", capabilityID) }
	req := plan.Request(capabilityID)
	if err := c.Check(ctx, req); err != nil { return capability.Result{}, fmt.Errorf("capability %s check failed: %w", capabilityID, err) }
	return c.Execute(ctx, req)
}
