package runtime

import (
	"testing"

	"github.com/opposum0112/Cusimanse/internal/execution"
	"github.com/opposum0112/Cusimanse/internal/model"
	"github.com/opposum0112/Cusimanse/internal/policy"
)

func TestPolicyFailsClosed(t *testing.T) {
	p := policy.NewEngine()
	if got := p.Evaluate("unknown-action", false).Decision; got != model.PolicyDeny { t.Fatalf("unknown action: got %s", got) }
	if got := p.Evaluate("push", false).Decision; got != model.PolicyApprovalRequired { t.Fatalf("push without approval: got %s", got) }
	if got := p.Evaluate("push", true).Decision; got != model.PolicyAllow { t.Fatalf("push with approval: got %s", got) }
	if got := p.Evaluate("public_gateway", true).Decision; got != model.PolicyDeny { t.Fatalf("denied action: got %s", got) }
}

func TestLifecycleGuardsDestroyUntilPreserved(t *testing.T) {
	if execution.CanTransition(model.StateReported, model.StateDestroyed) { t.Fatal("destroy must not bypass preservation") }
	if !execution.CanTransition(model.StateReported, model.StatePreserved) { t.Fatal("report must lead to preservation") }
	if !execution.CanTransition(model.StatePreserved, model.StateDestroyed) { t.Fatal("preservation must permit destroy") }
	if !execution.CanTransition(model.StateExecuting, model.StateEvidenceCollected) { t.Fatal("execution must collect evidence") }
}
