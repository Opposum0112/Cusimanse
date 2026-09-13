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
	if err != nil { fail(err) }
	if runtime.GOOS == "windows" && !runningInWSL() {
		fmt.Println("Cusimanse currently uses WSL2 for its Bash + Lima/QEMU execution path.")
		fmt.Println("Install/open WSL2, clone the repository inside WSL2, and rerun this command there.")
		os.Exit(2)
	}

	r := bufio.NewReader(os.Stdin)
	fmt.Println("Cusimanse interactive researcher host preparation")
	fmt.Printf("Host: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Printf("Repository: %s\n", root)
	fmt.Println("The bootstrap installs/checks the components for each plane and the flight-check audits the result.")
	fmt.Println("Profiles: 1 baseline, 2 research/control/learning, 3 observability/governance, 4 complete workstation, 5 check/repair")
	fmt.Print("Installation profile [4]: ")
	profile, _ := r.ReadString('\n')
	profile = strings.TrimSpace(profile)
	if profile == "" { profile = "4" }
	if !contains([]string{"1", "2", "3", "4", "5"}, profile) { fail(fmt.Errorf("invalid profile %q: choose 1-5", profile)) }

	if err := runBash(root, "scripts/prerequisites.sh", map[string]string{"CUSIMANSE_PROFILE": profile}); err != nil { fail(err) }
	fmt.Println("\nRunning comprehensive host flight-check...")
	if err := runBash(root, "scripts/agent-preflight.sh", nil); err != nil { fail(err) }

	policyctl := filepath.Join(root, "policyctl")
	if _, err := os.Stat(policyctl); err != nil {
		fmt.Println("Building policyctl for host-side validation...")
		cmd := exec.Command("go", "build", "-o", policyctl, "./cmd/policyctl")
		cmd.Dir, cmd.Stdout, cmd.Stderr = root, os.Stdout, os.Stderr
		if err := cmd.Run(); err != nil { fail(fmt.Errorf("policyctl build failed: %w", err)) }
	}
	if ask(r, "Run host-side policy validation now? [Y/n]: ", true) {
		if err := runExec(root, policyctl, "validate"); err != nil { fail(err) }
	}
	fmt.Println("\nCusimanse researcher host preparation complete.")
}

func findRoot() (string, error) {
	if v := os.Getenv("CUSIMANSE_ROOT"); v != "" { return filepath.Abs(v) }
	cwd, err := os.Getwd(); if err != nil { return "", err }
	for p := cwd; ; p = filepath.Dir(p) {
		if _, err := os.Stat(filepath.Join(p, "go.mod")); err == nil {
			if _, err := os.Stat(filepath.Join(p, "cmd", "cusimanse-host", "main.go")); err == nil { return p, nil }
		}
		n := filepath.Dir(p); if n == p { break }
	}
	return "", fmt.Errorf("cannot locate Cusimanse repository root; run from the checkout or set CUSIMANSE_ROOT")
}

func runningInWSL() bool { b, err := os.ReadFile("/proc/version"); return err == nil && strings.Contains(strings.ToLower(string(b)), "microsoft") }
func contains(xs []string, v string) bool { for _, x := range xs { if x == v { return true } }; return false }
func ask(r *bufio.Reader, prompt string, defaultYes bool) bool { fmt.Print(prompt); v, _ := r.ReadString('\n'); v = strings.ToLower(strings.TrimSpace(v)); if v == "" { return defaultYes }; return v == "y" || v == "yes" }

func runBash(root, relative string, extra map[string]string) error {
	bash, err := exec.LookPath("bash"); if err != nil { return fmt.Errorf("bash is required: %w", err) }
	cmd := exec.Command(bash, filepath.Join(root, relative)); cmd.Dir = root; cmd.Env = os.Environ()
	for k, v := range extra { cmd.Env = append(cmd.Env, k+"="+v) }
	cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin
	return cmd.Run()
}
func runExec(root, program string, args ...string) error { cmd := exec.Command(program, args...); cmd.Dir = root; cmd.Env = os.Environ(); cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin; return cmd.Run() }
func fail(err error) { fmt.Fprintf(os.Stderr, "Cusimanse setup failed: %v\n", err); os.Exit(1) }
