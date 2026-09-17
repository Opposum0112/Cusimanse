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
	"google.golang.org/adk/v2/workflow"
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

// New builds the native Go research runtime. The current graph is intentionally
// explicit: plan -> research -> analyze -> verify. The workflow state is owned
// by ADK session state; durable execution metadata is also written by the
// Cusimanse state journal used by the CLI.
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

	makeAgent := func(name, description, instruction string, tools []tool.Tool) (agent.Agent, error) {
		return llmagent.New(llmagent.Config{Name: name, Description: description, Model: m, Instruction: instruction, Tools: tools, OutputKey: name + "_output"})
	}
	planner, err := makeAgent("research_planner", "Creates a bounded security research plan from the declared request.", "Interpret the research request and define a bounded, authorized plan. Do not execute anything. State assumptions and acceptance criteria.", nil)
	if err != nil { return nil, err }
	researcher, err := makeAgent("security_researcher", "Performs authorized security research through Cusimanse capabilities.", "Execute the approved research plan only through request_capability. Never run shell commands directly. Treat capability output as observations and preserve the distinction between observations and reasoning.", []tool.Tool{capTool})
	if err != nil { return nil, err }
	analyzer, err := makeAgent("evidence_analyzer", "Analyzes collected security research observations and identifies candidate findings.", "Analyze only collected observations and preserved artifacts. Do not invent telemetry. Identify uncertainty and evidence gaps and request additional research only through the workflow.", nil)
	if err != nil { return nil, err }
	verifier, err := makeAgent("independent_verifier", "Independently verifies security findings against preserved evidence and acceptance criteria.", "Verify candidate findings independently. Reject unsupported conclusions. A verification result must cite the evidence that supports it and clearly distinguish verified facts from hypotheses.", nil)
	if err != nil { return nil, err }

	planNode, err := workflow.NewAgentNode(planner, workflow.NodeConfig{})
	if err != nil { return nil, fmt.Errorf("create plan node: %w", err) }
	researchNode, err := workflow.NewAgentNode(researcher, workflow.NodeConfig{})
	if err != nil { return nil, fmt.Errorf("create research node: %w", err) }
	analysisNode, err := workflow.NewAgentNode(analyzer, workflow.NodeConfig{})
	if err != nil { return nil, fmt.Errorf("create analysis node: %w", err) }
	verifyNode, err := workflow.NewAgentNode(verifier, workflow.NodeConfig{})
	if err != nil { return nil, fmt.Errorf("create verification node: %w", err) }
	graph, err := workflow.New("cusimanse_research_workflow", workflow.Chain(planNode, researchNode, analysisNode, verifyNode))
	if err != nil { return nil, fmt.Errorf("create research workflow: %w", err) }

	sessions := session.InMemoryService()
	mem := memory.InMemoryService()
	r, err := runner.New(runner.Config{AppName: cfg.AppName, Agent: graph, SessionService: sessions, MemoryService: mem, AutoCreateSession: true})
	if err != nil { return nil, fmt.Errorf("create ADK runner: %w", err) }
	return &Runtime{Config: cfg, Capabilities: registry, Policy: policy, Runner: r, Sessions: sessions, Memory: mem}, nil
}
