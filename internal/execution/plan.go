package execution

import (
	"fmt"
	"sort"

	"github.com/opposum0112/Cusimanse/internal/model"
)

type ExecutionPlan struct {
	ExperimentID     string
	SessionID        string
	HostProfile      string
	WorkloadProfile  string
	Capabilities     []string
	RequiredPolicies []string
	AgentID          string
	Role             string
	Skill            string
}

func NewPlan(experimentID, sessionID, hostProfile, workloadProfile string, capabilities, policies []string) (ExecutionPlan, error) {
	if experimentID == "" || sessionID == "" || hostProfile == "" || workloadProfile == "" {
		return ExecutionPlan{}, fmt.Errorf("execution plan requires experiment, session, host profile and workload profile")
	}
	caps := append([]string(nil), capabilities...)
	pol := append([]string(nil), policies...)
	sort.Strings(caps)
	sort.Strings(pol)
	return ExecutionPlan{ExperimentID: experimentID, SessionID: sessionID, HostProfile: hostProfile, WorkloadProfile: workloadProfile, Capabilities: caps, RequiredPolicies: pol}, nil
}

func (p ExecutionPlan) Request(capability string) model.CapabilityRequest {
	return model.CapabilityRequest{ExperimentID: p.ExperimentID, SessionID: p.SessionID, AgentID: p.AgentID, Role: p.Role, Skill: p.Skill, Capability: capability, WorkloadID: p.WorkloadProfile}
}
