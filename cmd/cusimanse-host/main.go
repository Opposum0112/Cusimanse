package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

func main() {
	root, err := findRoot()
	if err != nil { fmt.Fprintln(os.Stderr, err); os.Exit(1) }
	r := bufio.NewReader(os.Stdin)
	fmt.Println("Cusimanse interactive host preparation")
	fmt.Printf("Host: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Println("This front door runs the repository's vetted bootstrap and preflight controls.")
	fmt.Println()

	if ask(r, "Run comprehensive prerequisite installation? [Y/n]: ", true) {
		run(root, "scripts/prerequisites.sh", nil)
	}
	if ask(r, "Install the extended research/control/learning profile? [y/N]: ", false) {
		run(root, "scripts/prerequisites.sh", []string{"CUSIMANSE_INSTALL_PRODUCTION_PROFILE=1"})
	}
	if ask(r, "Install/verify agent observability and governance components? [Y/n]: ", true) {
		run(root, "scripts/prerequisites.sh", []string{"CUSIMANSE_INSTALL_OBSERVABILITY=1"})
	}
	if ask(r, "Install a primary agent (Prime Agent, Hermes or Goose)? [Y/n]: ", true) {
		fmt.Println("Agent installation is performed by the prerequisite bootstrap when supported.")
	}
	if ask(r, "Run full host preflight and capability checks now? [Y/n]: ", true) {
		run(root, "scripts/agent-preflight.sh", nil)
	}
	if ask(r, "Run policy validation now? [Y/n]: ", true) {
		run(root, "policyctl", []string{"validate"})
	}
	fmt.Println("\nHost preparation complete. Select one primary agent and start the research workflow from its shell.")
}

func findRoot() (string, error) {
	if v := os.Getenv("CUSIMANSE_ROOT"); v != "" { return v, nil }
	cwd, _ := os.Getwd()
	for p := cwd; ; p = filepath.Dir(p) {
		if _, err := os.Stat(filepath.Join(p, "scripts", "prerequisites.sh")); err == nil { return p, nil }
		next := filepath.Dir(p); if next == p { break }
	}
	return "", fmt.Errorf("cannot locate Cusimanse repository root; run from the repository or set CUSIMANSE_ROOT")
}

func ask(r *bufio.Reader, prompt string, defaultYes bool) bool {
	fmt.Print(prompt); v, _ := r.ReadString('\n'); v = strings.ToLower(strings.TrimSpace(v))
	if v == "" { return defaultYes }; return v == "y" || v == "yes"
}

func run(root, path string, settings []string) {
	full := filepath.Join(root, path)
	var cmd *exec.Cmd
	if path == "policyctl" { cmd = exec.Command(filepath.Join(root, "policyctl"), settings...) } else { cmd = exec.Command("bash", full) }
	cmd.Dir = root
	cmd.Env = os.Environ()
	for _, s := range settings {
		if strings.Contains(s, "=") { cmd.Env = append(cmd.Env, s) }
	}
	cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin
	if err := cmd.Run(); err != nil { fmt.Fprintf(os.Stderr, "Cusimanse setup command failed: %v\n", err); os.Exit(1) }
}
