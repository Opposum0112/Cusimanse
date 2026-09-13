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
	if runtime.GOOS == "windows" {
		fmt.Println("Cusimanse on Windows uses WSL2 for the Linux Lima/QEMU execution path.")
		fmt.Println("Open WSL2, cd to the repository there, and run: ./scripts/cusimanse-host.sh")
		return
	}
	r := bufio.NewReader(os.Stdin)
	fmt.Println("Cusimanse interactive host preparation")
	fmt.Printf("Host: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Println("One front door prepares all selected planes and finishes with a host preflight.")
	fmt.Println("Profiles: 1 baseline, 2 research/control/learning, 3 observability, 4 complete workstation, 5 check/repair")
	fmt.Print("Installation profile [4]: ")
	profile, _ := r.ReadString('\n'); profile = strings.TrimSpace(profile); if profile == "" { profile = "4" }
	if profile < "1" || profile > "5" { fmt.Fprintln(os.Stderr, "invalid profile: choose 1-5"); os.Exit(1) }
	run(root, "scripts/prerequisites.sh", []string{"CUSIMANSE_PROFILE=" + profile})
	fmt.Println()
	fmt.Println("Running comprehensive host preflight...")
	run(root, "scripts/agent-preflight.sh", nil)
	policyctl := filepath.Join(root, "policyctl")
	if _, err := os.Stat(policyctl); err != nil {
		fmt.Println("Building policyctl for host-side policy validation...")
		cmd := exec.Command("go", "build", "-o", policyctl, "./cmd/policyctl"); cmd.Dir = root; cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
		if err := cmd.Run(); err != nil { fmt.Fprintf(os.Stderr, "policyctl build failed: %v\n", err); os.Exit(1) }
	}
	run(root, "policyctl", []string{"validate"})
	fmt.Println("\nCusimanse host preparation complete.")
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

func run(root, path string, settings []string) {
	full := filepath.Join(root, path)
	var cmd *exec.Cmd
	if path == "policyctl" { cmd = exec.Command(full, settings...) } else { cmd = exec.Command("bash", full) }
	cmd.Dir = root; cmd.Env = os.Environ()
	for _, s := range settings { if strings.Contains(s, "=") { cmd.Env = append(cmd.Env, s) } }
	cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin
	if err := cmd.Run(); err != nil { fmt.Fprintf(os.Stderr, "Cusimanse setup command failed: %v\n", err); os.Exit(1) }
}
