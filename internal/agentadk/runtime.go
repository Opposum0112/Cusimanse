package agentadk

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/glebarez/sqlite"
	"github.com/opposum0112/Cusimanse/internal/capability"
	"github.com/opposum0112/Cusimanse/internal/model"
	policyengine "github.com/opposum0112/Cusimanse/internal/policy"
	"google.golang.org/adk/v2/agent"
	"google.golang.org/adk/v2/agent/llmagent"
	"google.golang.org/adk/v2/agent/workflowagent"
	"google.golang.org/adk/v2/memory"
	"google.golang.org/adk/v2/model/gemini"
	"google.golang.org/adk/v2/runner"
	"google.golang.org/adk/v2/session"
	"google.golang.org/adk/v2/session/database"
	"google.golang.org/adk/v2/tool"
	"google.golang.org/adk/v2/tool/functiontool"
	"google.golang.org/adk/v2/workflow"
	"google.golang.org/genai"
)

const maxResearchIterations = 3

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

type MemoryArgs struct { Query string `json:"query" jsonschema:"Search query for prior research context."` }
type MemoryResult struct { Results []string `json:"results"` }

type GateResult struct {
	Decision string `json:"decision"`
	Iteration int `json:"iteration"`
	Reason string `json:"reason"`
}

// New creates the native Go ADK runtime. ADK owns reasoning/orchestration;
// Cusimanse owns authorization and execution authority.
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

	memoryTool, err := functiontool.New(functiontool.Config{Name: "search_research_memory", Description: "Search ADK long-term memory for prior research context."}, func(tctx agent.Context, in MemoryArgs) (MemoryResult, error) {
		response, err := tctx.SearchMemory(context.Background(), in.Query)
		if err != nil { return MemoryResult{}, err }
		out := MemoryResult{}
		for _, entry := range response.Memories {
			if entry.Content == nil { continue }
			for _, part := range entry.Content.Parts { if part.Text != "" { out.Results = append(out.Results, part.Text) } }
		}
		return out, nil
	})
	if err != nil { return nil, fmt.Errorf("create memory tool: %w", err) }

	makeAgent := func(name, description, instruction string, tools []tool.Tool) (agent.Agent, error) {
		return llmagent.New(llmagent.Config{Name: name, Description: description, Model: m, Instruction: instruction, Tools: tools, OutputKey: name + "_output"})
	}
	planner, err := makeAgent("research_planner", "Creates a bounded security research plan.", "Interpret the research request and define a bounded, authorized plan. Do not execute anything. State assumptions and acceptance criteria. Consult prior research memory when useful.", []tool.Tool{memoryTool})
	if err != nil { return nil, err }
	researcher, err := makeAgent("security_researcher", "Performs authorized security research through Cusimanse capabilities.", "Execute the approved research plan only through request_capability. Never run shell commands directly. Treat capability output as observations and preserve the distinction between observations and reasoning. If the previous verification indicates a gap, focus only on the missing evidence.", []tool.Tool{capTool, memoryTool})
	if err != nil { return nil, err }
	analyzer, err := makeAgent("evidence_analyzer", "Analyzes collected security research observations.", "Analyze only collected observations and preserved artifacts. Do not invent telemetry. Memory is context, never evidence. Identify uncertainty and evidence gaps. Produce a concise evidence assessment for verification.", []tool.Tool{memoryTool})
	if err != nil { return nil, err }
	verifier, err := makeAgent("independent_verifier", "Independently verifies candidate security findings.", "Verify candidate findings against preserved evidence and acceptance criteria. Reject unsupported conclusions and distinguish verified facts from hypotheses. If evidence is incomplete, explicitly state the missing evidence and label the result GAP. If acceptance criteria are satisfied, label the result PASS.", nil)
	if err != nil { return nil, err }
	reporter, err := makeAgent("research_reporter", "Produces the final researcher-facing result.", "Summarize the completed security research using only preserved evidence, analysis, and verification. Clearly separate verified findings, observations, hypotheses, limitations, and evidence gaps. Do not invent facts and do not claim execution that did not occur.", nil)
	if err != nil { return nil, err }

	planNode, err := workflow.NewAgentNode(planner, workflow.NodeConfig{})
	if err != nil { return nil, fmt.Errorf("create plan node: %w", err) }
	researchNode, err := workflow.NewAgentNode(researcher, workflow.NodeConfig{})
	if err != nil { return nil, fmt.Errorf("create research node: %w", err) }
	analysisNode, err := workflow.NewAgentNode(analyzer, workflow.NodeConfig{})
	if err != nil { return nil, fmt.Errorf("create analysis node: %w", err) }
	verifyNode, err := workflow.NewAgentNode(verifier, workflow.NodeConfig{})
	if err != nil { return nil, fmt.Errorf("create verification node: %w", err) }
	reportNode, err := workflow.NewAgentNode(reporter, workflow.NodeConfig{})
	if err != nil { return nil, fmt.Errorf("create report node: %w", err) }

	gateNode := workflow.NewFunctionNode[any, *session.Event]("acceptance_gate", func(tctx agent.Context, _ any) (*session.Event, error) {
		iteration := 0
		if value, err := tctx.Session().State().Get("research_iteration"); err == nil {
			if n, ok := value.(int); ok { iteration = n }
		}
		iteration++
		decision := "GAP"
		reason := "verification did not explicitly establish acceptance"
		if value, err := tctx.Session().State().Get("independent_verifier_output"); err == nil {
			text := strings.ToUpper(fmt.Sprint(value))
			if strings.Contains(text, "PASS") && !strings.Contains(text, "GAP") {
				decision = "PASS"
				reason = "verification reported satisfied acceptance criteria"
			}
		}
		if iteration >= maxResearchIterations && decision != "PASS" {
			decision = "LIMIT"
			reason = fmt.Sprintf("bounded research loop reached %d iterations without a verified PASS", maxResearchIterations)
		}
		if tctx.Actions() != nil { tctx.Actions().StateDelta["research_iteration"] = iteration }
		event := session.NewEvent(tctx, tctx.InvocationID())
		event.Output = GateResult{Decision: decision, Iteration: iteration, Reason: reason}
		event.Routes = []string{decision}
		return event, nil
	}, workflow.NodeConfig{})

	edges := []workflow.Edge{
		{From: workflow.Start, To: planNode},
		{From: planNode, To: researchNode},
		{From: researchNode, To: analysisNode},
		{From: analysisNode, To: verifyNode},
		{From: verifyNode, To: gateNode},
		{From: gateNode, To: researchNode, Route: workflow.StringRoute("GAP")},
		{From: gateNode, To: reportNode, Route: workflow.MultiRoute[string]{"PASS", "LIMIT"}},
	}
	root, err := workflowagent.New(workflowagent.Config{
		Name: "cusimanse_research_workflow",
		Description: "Bounded adaptive security research workflow.",
		Edges: edges,
		SubAgents: []agent.Agent{planner, researcher, analyzer, verifier, reporter},
	})
	if err != nil { return nil, fmt.Errorf("create adaptive research workflow: %w", err) }

	dbPath := os.Getenv("CUSIMANSE_ADK_SESSION_DB")
	if dbPath == "" { dbPath = filepath.Join(".cusimanse", "adk-sessions.db") }
	if err := os.MkdirAll(filepath.Dir(dbPath), 0o700); err != nil { return nil, fmt.Errorf("create ADK session database directory: %w", err) }
	sessions, err := database.NewSessionService(sqlite.Open(dbPath))
	if err != nil { return nil, fmt.Errorf("create persistent ADK session service: %w", err) }
	if err := database.AutoMigrate(sessions); err != nil { return nil, fmt.Errorf("migrate ADK session database: %w", err) }
	mem := memory.InMemoryService()
	r, err := runner.New(runner.Config{AppName: cfg.AppName, Agent: root, SessionService: sessions, MemoryService: mem, AutoCreateSession: true})
	if err != nil { return nil, fmt.Errorf("create ADK runner: %w", err) }
	return &Runtime{Config: cfg, Capabilities: registry, Policy: policy, Runner: r, Sessions: sessions, Memory: mem}, nil
}
