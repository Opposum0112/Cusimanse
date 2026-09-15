package model

import "time"

type Requirements struct {
	Execution      string
	OS             string
	Workload       string
	Network        string
	Instrumentation []string
}

type Experiment struct {
	ID           string
	Requirements Requirements
	Policy       []string
}

type CapabilitySpec struct {
	ID          string
	Version     string
	Description string
	Inputs      []string
	Outputs     []string
}

type CapabilityRequest struct {
	ExperimentID string
	SessionID    string
	RunID        string
	AgentID      string
	Role         string
	Skill        string
	Capability   string
	WorkloadID   string
	Parameters   map[string]string
}

type PolicyDecision string

const (
	PolicyAllow           PolicyDecision = "allow"
	PolicyApprovalRequired PolicyDecision = "approval-required"
	PolicyDeny            PolicyDecision = "deny"
	PolicyRequired        PolicyDecision = "required"
)

type Decision struct {
	Action   string
	Decision PolicyDecision
	Reason   string
}

type SessionState string

const (
	StateCreated            SessionState = "CREATED"
	StateValidated          SessionState = "VALIDATED"
	StatePlanned            SessionState = "PLANNED"
	StateProvisioned        SessionState = "PROVISIONED"
	StateInstrumented       SessionState = "INSTRUMENTED"
	StateExecuting          SessionState = "EXECUTING"
	StateEvidenceCollected  SessionState = "EVIDENCE_COLLECTED"
	StateVerified           SessionState = "VERIFIED"
	StateReported           SessionState = "REPORTED"
	StatePreserved          SessionState = "PRESERVED"
	StateDestroyed          SessionState = "DESTROYED"
	StateFailed             SessionState = "FAILED"
)

type Session struct {
	ID           string
	ExperimentID string
	AgentID      string
	State        SessionState
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type EvidenceItem struct {
	Path      string
	SHA256    string
	CollectedAt time.Time
	Capability string
}

type RunResult struct {
	SessionID string
	RunID     string
	State     SessionState
	Evidence  []EvidenceItem
	Error     string
}
