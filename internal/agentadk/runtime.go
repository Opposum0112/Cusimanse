package agentadk

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/glebarez/sqlite"
	"github.com/opposum0112/Cusimanse/internal/capability"
	"github.com/opposum0112/Cusimanse/internal/evidence"
	"github.com/opposum0112/Cusimanse/internal/execution"
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
	Config       Config
	Capabilities *capability.Registry
	Policy       *policyengine.Engine
	Runner       *runner.Runner
	Sessions     session.Service
	Memory       memory.Service
	Journal      *execution.Journal
	Evidence     *evidence.Store
}

type CapabilityArgs struct {
	Capability   string            `json:"capability" jsonschema:"Registered Cusimanse capability ID."`
	ExperimentID string            `json:"experiment_id,omitempty" jsonschema:"Experiment or contract identifier."`
	SessionID    string            `json:"session_id,omitempty" jsonschema:"Research session identifier."`
	RunID        string            `json:"run_id,omitempty" jsonschema:"Research run identifier."`
	Parameters   map[string]string `json:"parameters,omitempty" jsonschema:"Capability parameters."`
}

type CapabilityResult struct {
	Capability string `json:"capability"`
	Decision   string `json:"decision"`
	Reason     string `json:"reason"`
	Started    bool   `json:"started"`
	Completed  bool   `json:"completed"`
	Message    string `json:"message,omitempty"`
	EvidenceID string `json:"evidence_id,omitempty"`
}

type MemoryArgs struct {
	Query string `json:"query" jsonschema:"Search query for prior research context."`
}

type MemoryResult struct {
	Results []string `json:"results"`
}

type ResearchResult struct {
	Report     string `json:"report"`
	Iterations int    `json:"iterations"`
	Decision   string `json:"decision"`
}

// New creates the native Go ADK runtime. ADK owns reasoning/orchestration;
// Cusimanse owns authorization, execution authority, journal, and evidence.
func New(ctx context.Context, cfg Config, registry *capability.Registry) (*Runtime, error) {
	if registry == nil {
		registry = capability.NewRegistry()
	}
	apiKey := os.Getenv("GOOGLE_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("GOOGLE_API_KEY is required for the initial ADK Go runtime")
	}
	m, err := gemini.NewModel(ctx, cfg.Model, &genai.ClientConfig{APIKey: apiKey})
	if err != nil {
		return nil, fmt.Errorf("create ADK Gemini model: %w", err)
	}
	policy := policyengine.NewEngine()

	stateDir := os.Getenv("CUSIMANSE_STATE_DIR")
	if stateDir == "" {
		stateDir = ".cusimanse"
	}
	journal, err := execution.New(filepath.Join(stateDir, "execution"))
	if err != nil {
		return nil, fmt.Errorf("create execution journal: %w", err)
	}
	evidenceStore, err := evidence.New(filepath.Join(stateDir, "evidence"))
	if err != nil {
		return nil, fmt.Errorf("create evidence store: %w", err)
	}

	capTool, err := functiontool.New(functiontool.Config{
		Name:        "request_capability",
		Description: "Request a registered Cusimanse capability. Policy is evaluated before any approval prompt and before execution.",
		RequireConfirmationProvider: func(in CapabilityArgs) bool {
			return policy.Evaluate(in.Capability, cfg.Approved).Decision == model.PolicyAllow
		},
	}, func(tctx agent.Context, in CapabilityArgs) (CapabilityResult, error) {
		c, ok := registry.Get(in.Capability)
		if !ok {
			return CapabilityResult{Capability: in.Capability, Decision: model.PolicyDeny, Reason: "capability is not registered"}, nil
		}
		decision := policy.Evaluate(in.Capability, cfg.Approved)
		if decision.Decision != model.PolicyAllow {
			return CapabilityResult{Capability: in.Capability, Decision: decision.Decision, Reason: decision.Reason}, nil
		}
		req := model.CapabilityRequest{ExperimentID: in.ExperimentID, SessionID: in.SessionID, RunID: in.RunID, Capability: in.Capability, Parameters: in.Parameters}
		opID := execution.OperationID(in.SessionID, in.RunID, in.Capability, in.Parameters)
		if prior, err := journal.Get(opID); err == nil {
			switch prior.Status {
			case execution.Completed:
				return CapabilityResult{Capability: in.Capability, Decision: model.PolicyAllow, Reason: "idempotent replay returned the previously completed operation", Started: true, Completed: true, Message: prior.Message}, nil
			case execution.Running, execution.AmbiguousEffect:
				return CapabilityResult{Capability: in.Capability, Decision: model.PolicyDeny, Reason: "operation has unresolved side effects; reconcile evidence before retrying", Started: true, Completed: false, Message: prior.Message}, nil
			}
		}
		if err := c.Check(tctx, req); err != nil {
			_ = journal.Put(execution.Entry{OperationID: opID, SessionID: in.SessionID, RunID: in.RunID, Capability: in.Capability, Status: execution.Failed, Message: "preflight denied: " + err.Error()})
			return CapabilityResult{Capability: in.Capability, Decision: model.PolicyDeny, Reason: err.Error()}, nil
		}
		if err := journal.Put(execution.Entry{OperationID: opID, SessionID: in.SessionID, RunID: in.RunID, Capability: in.Capability, RequestHash: opID, Status: execution.Pending}); err != nil {
			return CapabilityResult{}, fmt.Errorf("journal pending operation: %w", err)
		}
		if _, err := journal.Update(opID, execution.Running, "capability execution started"); err != nil {
			return CapabilityResult{}, fmt.Errorf("journal running operation: %w", err)
		}
		result, execErr := c.Execute(tctx, req)
		if execErr != nil {
			status := execution.Failed
			if result.Started && !result.Completed {
				status = execution.AmbiguousEffect
			}
			_, _ = journal.Update(opID, status, execErr.Error())
			return CapabilityResult{Capability: in.Capability, Decision: model.PolicyDeny, Reason: execErr.Error(), Started: result.Started, Completed: result.Completed, Message: result.Message}, nil
		}
		message := result.Message
		if _, err := journal.Update(opID, execution.Completed, message); err != nil {
			return CapabilityResult{}, fmt.Errorf("journal completed operation: %w", err)
		}
		resultOut := CapabilityResult{Capability: in.Capability, Decision: model.PolicyAllow, Reason: "capability executed by Cusimanse Go runtime", Started: result.Started, Completed: result.Completed, Message: message}
		if message != "" {
			evidenceID := evidence.NewID(in.SessionID, in.RunID, in.Capability, "capability-observation", message)
			if err := evidenceStore.Put(evidence.Record{ID: evidenceID, SessionID: in.SessionID, RunID: in.RunID, Source: in.Capability, Kind: "capability-observation", Content: message, Metadata: map[string]string{"operation_id": opID}}); err != nil {
				return CapabilityResult{}, fmt.Errorf("preserve capability evidence: %w", err)
			}
			resultOut.EvidenceID = evidenceID
		}
		return resultOut, nil
	})
	if err != nil {
		return nil, fmt.Errorf("create capability tool: %w", err)
	}

	memoryTool, err := functiontool.New(functiontool.Config{Name: "search_research_memory", Description: "Search ADK long-term memory for prior research context."}, func(tctx agent.Context, in MemoryArgs) (MemoryResult, error) {
		response, err := tctx.SearchMemory(context.Background(), in.Query)
		if err != nil {
			return MemoryResult{}, err
		}
		out := MemoryResult{}
		for _, entry := range response.Memories {
			if entry.Content == nil {
				continue
			}
			for _, part := range entry.Content.Parts {
				if part.Text != "" {
					out.Results = append(out.Results, part.Text)
				}
			}
		}
		return out, nil
	})
	if err != nil {
		return nil, fmt.Errorf("create memory tool: %w", err)
	}

	makeAgent := func(name, description, instruction string, tools []tool.Tool) (agent.Agent, error) {
		return llmagent.New(llmagent.Config{Name: name, Description: description, Model: m, Instruction: instruction, Tools: tools, OutputKey: name + "_output"})
	}
	planner, err := makeAgent("research_planner", "Creates a bounded security research plan.", "Interpret the research request and define a bounded, authorized plan. Do not execute anything. State assumptions and acceptance criteria. Consult prior research memory when useful.", []tool.Tool{memoryTool})
	if err != nil {
		return nil, err
	}
	researcher, err := makeAgent("security_researcher", "Performs authorized security research through Cusimanse capabilities.", "Execute the approved research plan only through request_capability. Never run shell commands directly. Treat capability output as observations. If verification reports a gap, focus only on the missing evidence.", []tool.Tool{capTool, memoryTool})
	if err != nil {
		return nil, err
	}
	analyzer, err := makeAgent("evidence_analyzer", "Analyzes collected security research observations.", "Analyze only collected observations and preserved artifacts. Do not invent telemetry. Memory is context, never evidence. Identify uncertainty and evidence gaps. Produce a concise evidence assessment for verification.", []tool.Tool{memoryTool})
	if err != nil {
		return nil, err
	}
	verifier, err := makeAgent("independent_verifier", "Independently verifies candidate security findings.", "Verify candidate findings against preserved evidence and acceptance criteria. Reject unsupported conclusions. If evidence is incomplete, explicitly state the missing evidence and label the result GAP. If acceptance criteria are satisfied, label the result PASS.", nil)
	if err != nil {
		return nil, err
	}
	reporter, err := makeAgent("research_reporter", "Produces the final researcher-facing result.", "Summarize completed research using only preserved evidence, analysis, and verification. Separate verified findings, observations, hypotheses, limitations, and evidence gaps. Never claim execution that did not occur.", nil)
	if err != nil {
		return nil, err
	}

	planNode, err := workflow.NewAgentNode(planner, workflow.NodeConfig{})
	if err != nil {
		return nil, fmt.Errorf("create plan node: %w", err)
	}
	researchNode, err := workflow.NewAgentNode(researcher, workflow.NodeConfig{})
	if err != nil {
		return nil, fmt.Errorf("create research node: %w", err)
	}
	analysisNode, err := workflow.NewAgentNode(analyzer, workflow.NodeConfig{})
	if err != nil {
		return nil, fmt.Errorf("create analysis node: %w", err)
	}
	verifyNode, err := workflow.NewAgentNode(verifier, workflow.NodeConfig{})
	if err != nil {
		return nil, fmt.Errorf("create verification node: %w", err)
	}
	reportNode, err := workflow.NewAgentNode(reporter, workflow.NodeConfig{})
	if err != nil {
		return nil, fmt.Errorf("create report node: %w", err)
	}

	// The dynamic node is the adaptive controller. ADK persists its run state;
	// RunNode re-enters children using durable node checkpoints on resume.
	dynamic := workflow.NewDynamicNode[any, ResearchResult]("adaptive_research", func(tctx agent.Context, input any, _ func(*session.Event) error) (ResearchResult, error) {
		plan, err := workflow.RunNode[any](tctx, planNode, input, workflow.WithRunID("plan"))
		if err != nil {
			return ResearchResult{}, err
		}
		current := plan
		for iteration := 1; iteration <= maxResearchIterations; iteration++ {
			research, err := workflow.RunNode[any](tctx, researchNode, current, workflow.WithRunID(fmt.Sprintf("research-%d", iteration)))
			if err != nil {
				return ResearchResult{}, err
			}
			analysis, err := workflow.RunNode[any](tctx, analysisNode, research, workflow.WithRunID(fmt.Sprintf("analysis-%d", iteration)))
			if err != nil {
				return ResearchResult{}, err
			}
			verification, err := workflow.RunNode[any](tctx, verifyNode, analysis, workflow.WithRunID(fmt.Sprintf("verify-%d", iteration)))
			if err != nil {
				return ResearchResult{}, err
			}
			verificationText := strings.ToUpper(fmt.Sprint(verification))
			if strings.Contains(verificationText, "PASS") && !strings.Contains(verificationText, "GAP") {
				report, err := workflow.RunNode[any](tctx, reportNode, verification, workflow.WithRunID(fmt.Sprintf("report-%d", iteration)))
				if err != nil {
					return ResearchResult{}, err
				}
				return ResearchResult{Report: fmt.Sprint(report), Iterations: iteration, Decision: "PASS"}, nil
			}
			current = fmt.Sprintf("Previous verification was GAP. Refine only the missing evidence. Verification: %s", verification)
		}
		report, err := workflow.RunNode[any](tctx, reportNode, current, workflow.WithRunID("report-limit"))
		if err != nil {
			return ResearchResult{}, err
		}
		return ResearchResult{Report: fmt.Sprint(report), Iterations: maxResearchIterations, Decision: "LIMIT"}, nil
	}, workflow.NodeConfig{})

	root, err := workflowagent.New(workflowagent.Config{
		Name:        "cusimanse_research_workflow",
		Description: "Bounded adaptive security research workflow.",
		Edges:       workflow.Chain(workflow.Start, dynamic),
		SubAgents:   []agent.Agent{planner, researcher, analyzer, verifier, reporter},
	})
	if err != nil {
		return nil, fmt.Errorf("create adaptive research workflow: %w", err)
	}

	dbPath := os.Getenv("CUSIMANSE_ADK_SESSION_DB")
	if dbPath == "" {
		dbPath = filepath.Join(stateDir, "adk-sessions.db")
	}
	if err := os.MkdirAll(filepath.Dir(dbPath), 0o700); err != nil {
		return nil, fmt.Errorf("create ADK session database directory: %w", err)
	}
	sessions, err := database.NewSessionService(sqlite.Open(dbPath))
	if err != nil {
		return nil, fmt.Errorf("create persistent ADK session service: %w", err)
	}
	if err := database.AutoMigrate(sessions); err != nil {
		return nil, fmt.Errorf("migrate ADK session database: %w", err)
	}
	mem := memory.InMemoryService()
	r, err := runner.New(runner.Config{AppName: cfg.AppName, Agent: root, SessionService: sessions, MemoryService: mem, AutoCreateSession: true})
	if err != nil {
		return nil, fmt.Errorf("create ADK runner: %w", err)
	}
	return &Runtime{Config: cfg, Capabilities: registry, Policy: policy, Runner: r, Sessions: sessions, Memory: mem, Journal: journal, Evidence: evidenceStore}, nil
}
