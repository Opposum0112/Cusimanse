package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"os"
	"strings"
	"time"

	adkruntime "github.com/opposum0112/Cusimanse/internal/agentadk"
	"github.com/opposum0112/Cusimanse/internal/capability"
	"github.com/opposum0112/Cusimanse/internal/state"
	"google.golang.org/adk/v2/agent"
	"google.golang.org/genai"
)

func main() {
	model := flag.String("model", "", "ADK model ID; defaults to CUSIMANSE_MODEL or gemini-2.5-flash")
	sessionID := flag.String("session", "", "stable research session ID; generated when omitted")
	approved := flag.Bool("approved", false, "allow policy actions that explicitly require approval")
	stateDir := flag.String("state-dir", ".cusimanse/state", "durable research state directory")
	flag.Parse()

	cfg := adkruntime.DefaultConfig()
	if *model != "" { cfg.Model = *model }
	cfg.Approved = *approved
	if *sessionID == "" { *sessionID = fmt.Sprintf("research-%d", time.Now().UTC().UnixNano()) }

	ctx := context.Background()
	registry := capability.NewRegistry()
	rt, err := adkruntime.New(ctx, cfg, registry)
	if err != nil { fatal(err) }
	store, err := state.New(*stateDir)
	if err != nil { fatal(err) }

	if previous, err := store.Load(*sessionID); err == nil {
		fmt.Printf("Resuming durable session %s (phase=%s status=%s updated=%s)\n", previous.SessionID, previous.Phase, previous.Status, previous.UpdatedAt.Format(time.RFC3339))
	} else if !os.IsNotExist(err) {
		fatal(fmt.Errorf("load durable session: %w", err))
	}
	if err := store.Save(state.Record{SessionID: *sessionID, RunID: *sessionID, Phase: "start", Status: "RUNNING"}); err != nil { fatal(err) }

	fmt.Printf("Cusimanse ADK Go 2 security research agent\nmodel=%s session=%s\n", cfg.Model, *sessionID)
	fmt.Println("Type /exit to stop. Capability execution is always mediated by the Go policy boundary.")
	reader := bufio.NewReader(os.Stdin)
	userID := "researcher"
	for {
		fmt.Print("> ")
		line, err := reader.ReadString('\n')
		if err != nil { break }
		line = strings.TrimSpace(line)
		if line == "" { continue }
		if line == "/exit" || line == "/quit" { break }

		if err := store.Save(state.Record{SessionID: *sessionID, RunID: *sessionID, Phase: "turn-running", Status: "RUNNING", State: map[string]any{"request": line}}); err != nil { fatal(err) }
		msg := genai.NewContentFromText(line, "user")
		failed := false
		for event, runErr := range rt.Runner.Run(ctx, userID, *sessionID, msg, agent.RunConfig{}) {
			if runErr != nil {
				failed = true
				fmt.Fprintf(os.Stderr, "agent error: %v\n", runErr)
				_ = store.Save(state.Record{SessionID: *sessionID, RunID: *sessionID, Phase: "error", Status: "FAILED", State: map[string]any{"error": runErr.Error(), "request": line}})
				break
			}
			if event != nil && event.Content != nil {
				for _, part := range event.Content.Parts { if part.Text != "" { fmt.Print(part.Text) } }
				fmt.Println()
			}
		}
		if !failed {
			_ = store.Save(state.Record{SessionID: *sessionID, RunID: *sessionID, Phase: "turn-complete", Status: "RUNNING", State: map[string]any{"request": line}})
		}
	}
	_ = store.Save(state.Record{SessionID: *sessionID, RunID: *sessionID, Phase: "stop", Status: "COMPLETED"})
}

func fatal(err error) { fmt.Fprintln(os.Stderr, err); os.Exit(1) }
