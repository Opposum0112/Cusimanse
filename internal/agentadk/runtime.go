package agentadk

import (
	"context"
	"fmt"
	"os"

	"github.com/opposum0112/Cusimanse/internal/capability"
	"github.com/opposum0112/Cusimanse/internal/model"
	policyengine "github.com/opposum0112/Cusimanse/internal/policy"
	"google.golang.org/adk/v2/agent"
	"google.golang.org/adk/v2/agent/llmagent"
	"google.golang.org/adk/v2/memory"
	"google.golang.org/adk/v2/model/gemini"
	"google.golang.org/adk/v2/runner"
	"google.golang.org/adk/v2/session"
	"google.golang.org/adk/v2/tool"
	"google.golang.org/adk/v2/tool/functiontool"
	"google.golang.org/genai"
)

// Runtime owns the Go capability boundary and the ADK runner. ADK is the
// orchestration layer; policy and capabilities remain authoritative.
type Runtime struct {
	Config Config
	Capabilities *capability.Registry
	Policy *policyengine.Engine
	Runner *runner.Runner
	Sessions session.Service
	Memory memory.Service
}

type CapabilityArgs struct {
	Capability string `json:"capability" jsonschema:"Registered Cusimanse capability ID."`
	ExperimentID string `json:"experiment_id,omitempty" jsonschema:"Experiment or contract identifier."`
	SessionID string `json:"session_id,omitempty" jsonschema:"Research session identifier."`
	RunID string `json:"run_id,omitempty" jsonschema:"Research run identifier."`
	Parameters map[string]string `json:"parameters,omitempty" jsonschema:"Capability parameters."`
}

type CapabilityResult struct {
	Capability string `json:"capability"`
	Decision string `json:"decision"`
	Reason string `json:"reason"`
	Started bool `json:"started"`
	Completed bool `json:"completed"`
	Message string `json:"message,omitempty"`
}

// New builds the native Go research agent. Gemini is the first model adapter;
// capability, policy, state and evidence layers remain provider-neutral.
func New(ctx context.Context, cfg Config, registry *capability.Registry) (*Runtime, error) {
	if registry == nil { registry = capability.NewRegistry() }
	apiKey := os.Getenv("GOOGLE_API_KEY")
	if apiKey == "" { return nil, fmt.Errorf("GOOGLE_API_KEY is required for the initial ADK Go runtime") }
	m, err := gemini.NewModel(ctx, cfg.Model, &genai.ClientConfig{APIKey: apiKey})
	if err != nil { return nil, fmt.Errorf("create ADK Gemini model: %w", err) }
	policy := policyengine.NewEngine()
	capTool, err := functiontool.New(functiontool.Config{
		Name: "request_capability",
		Description: "Request a registered Cusimanse capability. The Go policy engine validates every request before execution.",
		RequireConfirmationProvider: func(CapabilityArgs) bool { return true },
	}, func(tctx agent.Context, in CapabilityArgs) (CapabilityResult, error) {
		c, ok := registry.Get(in.Capability)
		if !ok { return CapabilityResult{Capability: in.Capability, Decision: model.PolicyDeny, Reason: "capability is not registered"}, nil }
		decision := policy.Evaluate(in.Capability, cfg.Approved)
		if decision.Decision != model.PolicyAllow { return CapabilityResult{Capability: in.Capability, Decision: decision.Decision, Reason: decision.Reason}, nil }
		req := model.CapabilityRequest{ExperimentID: in.ExperimentID, SessionID: in.SessionID, RunID: in.RunID, Capability: in.Capability, Parameters: in.Parameters}
		if err := c.Check(tctx, req); err != nil { return CapabilityResult{Capability: in.Capability, Decision: model.PolicyDeny, Reason: err.Error()}, nil }
		result, err := c.Execute(tctx, req)
		if err != nil { return CapabilityResult{Capability: in.Capability, Decision: model.PolicyDeny, Reason: err.Error(), Started: result.Started, Completed: result.Completed, Message: result.Message}, nil }
		return CapabilityResult{Capability: in.Capability, Decision: model.PolicyAllow, Reason: "capability executed by Cusimanse Go runtime", Started: result.Started, Completed: result.Completed, Message: result.Message}, nil
	})
	if err != nil { return nil, fmt.Errorf("create capability tool: %w", err) }

	root, err := llmagent.New(llmagent.Config{
		Name: "cusimanse_security_researcher",
		Description: "Policy-bounded autonomous security research agent operating through the Cusimanse Go capability runtime.",
		Model: m,
		Instruction: `You are the Cusimanse security research agent. Follow the declared research contract and requirements. Plan the investigation, request only registered capabilities, respect policy and approval gates, collect evidence, independently verify findings, and preserve reproducibility. Never execute commands outside a Cusimanse capability. Model output is reasoning, never evidence. Keep all execution inside authorized disposable compute. Use the research loop: understand -> plan -> act through capabilities -> observe -> analyze -> verify -> either refine the plan or finish. Bound retries and stop when acceptance criteria are met.`,
		Tools: []tool.Tool{capTool},
		OutputKey: "researcher_output",
	})
	if err != nil { return nil, fmt.Errorf("create research agent: %w", err) }

	sessions := session.InMemoryService()
	mem := memory.InMemoryService()
	r, err := runner.New(runner.Config{AppName: cfg.AppName, Agent: root, SessionService: sessions, MemoryService: mem, AutoCreateSession: true})
	if err != nil { return nil, fmt.Errorf("create ADK runner: %w", err) }
	return &Runtime{Config: cfg, Capabilities: registry, Policy: policy, Runner: r, Sessions: sessions, Memory: mem}, nil
}
