package policy

import (
	"fmt"
	"strings"

	"github.com/opposum0112/Cusimanse/internal/model"
)

// Engine is the small policy boundary used by the runtime. The YAML policy
// remains the source of truth; this evaluator intentionally fails closed for
// actions it does not understand until their mapping is explicitly defined.
type Engine struct {
	allow map[string]bool
	approval map[string]bool
	deny map[string]bool
}

func NewEngine() *Engine {
	return &Engine{
		allow: map[string]bool{"lima": true, "qemu": true, "read": true, "localhost_services": true, "primary_agent_native_orchestration": true},
		approval: map[string]bool{"disposable_vm": true, "sudo": true, "network_reconfiguration": true, "write": true, "push": true, "learning_helpers": true},
		deny: map[string]bool{"credentials": true, "unrestricted_mounts": true, "untrusted_host_execution": true, "host_filesystem": true, "public_mcp": true, "public_gateway": true, "competing_orchestrator": true},
	}
}

func (e *Engine) Evaluate(action string, approved bool) model.Decision {
	action = strings.TrimSpace(action)
	if action == "" { return model.Decision{Action: action, Decision: model.PolicyDeny, Reason: "empty action"} }
	if e.deny[action] { return model.Decision{Action: action, Decision: model.PolicyDeny, Reason: "action is explicitly denied"} }
	if e.allow[action] { return model.Decision{Action: action, Decision: model.PolicyAllow, Reason: "action is explicitly allowed"} }
	if e.approval[action] {
		if approved { return model.Decision{Action: action, Decision: model.PolicyAllow, Reason: "explicit approval supplied"} }
		return model.Decision{Action: action, Decision: model.PolicyApprovalRequired, Reason: "explicit researcher approval is required"}
	}
	return model.Decision{Action: action, Decision: model.PolicyDeny, Reason: fmt.Sprintf("unknown policy action %q; failing closed", action)}
}
