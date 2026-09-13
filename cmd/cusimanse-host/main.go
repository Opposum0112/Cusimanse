package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

func main() {
	r := bufio.NewReader(os.Stdin)
	fmt.Println("Cusimanse host configuration")
	fmt.Printf("Host: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Println("The Go entrypoint is the interactive front door; vetted repository scripts remain the installation implementation.")
	fmt.Println()
	if ask(r, "Install mandatory host and VM prerequisites? [Y/n]: ", true) {
		run("./scripts/prerequisites.sh", nil)
	} else { return }
	if ask(r, "Install ALL optional security-research components? [y/N]: ", false) {
		run("./scripts/prerequisites.sh", []string{"CUSIMANSE_INSTALL_PRODUCTION_PROFILE=1"})
	}
	if ask(r, "Install/verify agent observability (OpenTelemetry + Phoenix; Numbat/Aegis only with verified adapters)? [Y/n]: ", true) {
		run("./scripts/prerequisites.sh", []string{"CUSIMANSE_INSTALL_OBSERVABILITY=1"})
	}
	fmt.Println("Host configuration complete. Continue with ./scripts/agent-preflight.sh and policyctl validate in the normal host shell.")
}

func ask(r *bufio.Reader, prompt string, defaultYes bool) bool {
	fmt.Print(prompt)
	v, _ := r.ReadString('\n')
	v = strings.ToLower(strings.TrimSpace(v))
	if v == "" { return defaultYes }
	return v == "y" || v == "yes"
}

func run(path string, settings []string) {
	cmd := exec.Command("bash", path)
	cmd.Env = append(os.Environ(), settings...)
	cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin
	if err := cmd.Run(); err != nil { os.Exit(1) }
}
