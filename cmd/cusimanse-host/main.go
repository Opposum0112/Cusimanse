package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

const statePath = "recipes/host-state.yaml"

type setupState struct {
	startedAt     string
	completedAt   string
	adapter       string
	foundation    string
	primary       string
	control       string
	observability string
	validation    string
	vmStatus      string
	vmInventory   string
}

func main() {
	root, err := findRoot()
	if err != nil {
		fail(err)
	}
	if runtime.GOOS == "windows" && !runningInWSL() {
		fmt.Println("Cusimanse Linux/Lima path is supported on Windows through WSL2.")
		fmt.Println("Fallback: install/use WSL2, clone the repository inside WSL, then rerun ./scripts/cusimanse-host.sh.")
		os.Exit(2)
	}
	r := bufio.NewReader(os.Stdin)
	state := newState()
	writeState(root, state)

	fmt.Println("Cusimanse interactive researcher host preparation")
	fmt.Printf("Host: %s/%s\nRepository: %s\n", runtime.GOOS, runtime.GOARCH, root)
	fmt.Println("Distro/OS-neutral front door: detect → preflight → install by capability → configure → validate.")
	fmt.Println("State is recorded in recipes/host-state.yaml after every stage, including detailed Lima VM discovery.")

	if ask(r, "1. Foundation: install/repair host + VM prerequisites? [Y/n]: ", true) {
		state.stage("foundation", "RUNNING")
		writeState(root, state)
		must(runBash(root, "scripts/prerequisites.sh", map[string]string{"CUSIMANSE_PROFILE": "1"}))
		state.stage("foundation", "PASS")
	} else {
		state.stage("foundation", "SKIPPED")
	}
	writeState(root, state)

	adapter := chooseAdapter(r)
	if adapter != "none" && ask(r, "2. Primary agent: install/check selected adapter? [Y/n]: ", true) {
		state.stage("primary_agent", "RUNNING")
		state.adapter = adapter
		writeState(root, state)
		must(runBash(root, "scripts/prerequisites.sh", map[string]string{"CUSIMANSE_PROFILE": "1", "CUSIMANSE_INSTALL_AGENTS": "1", "CUSIMANSE_PRIMARY_ADAPTER": adapter}))
		must(runBash(root, "scripts/configure-recipes.sh", map[string]string{"CUSIMANSE_PRIMARY_ADAPTER": adapter}))
		state.stage("primary_agent", "PASS")
	} else {
		state.stage("primary_agent", "SKIPPED")
	}
	writeState(root, state)

	if ask(r, "3. Control + learning: install/check control-plane capabilities? [Y/n]: ", true) {
		state.stage("control_learning", "RUNNING")
		writeState(root, state)
		must(runBash(root, "scripts/prerequisites.sh", map[string]string{"CUSIMANSE_PROFILE": "2"}))
		state.stage("control_learning", "PASS")
	} else {
		state.stage("control_learning", "SKIPPED")
	}
	writeState(root, state)

	if ask(r, "4. Observability + governance: install/check OTEL/Phoenix/Numbat/Aegis? [Y/n]: ", true) {
		state.stage("observability_governance", "RUNNING")
		writeState(root, state)
		must(runBash(root, "scripts/prerequisites.sh", map[string]string{"CUSIMANSE_PROFILE": "3"}))
		must(runBash(root, "scripts/install-observability.sh", nil))
		must(runBash(root, "scripts/configure-recipes.sh", map[string]string{"CUSIMANSE_OBSERVABILITY_STATUS": "CONFIGURED"}))
		state.stage("observability_governance", "PASS")
	} else {
		state.stage("observability_governance", "SKIPPED")
	}
	writeState(root, state)

	fmt.Println("\n5. Validation: running comprehensive preflight and policy checks...")
	state.stage("validation", "RUNNING")
	writeState(root, state)
	must(runBash(root, "scripts/agent-preflight.sh", map[string]string{"CUSIMANSE_PRIMARY_ADAPTER": adapter}))
	buildPolicyctl(root)
	if ask(r, "Run policy validation now? [Y/n]: ", true) {
		must(runExec(root, filepath.Join(root, "policyctl"), "validate"))
	}
	state.stage("validation", "PASS")
	state.vmStatus, state.vmInventory = discoverVM(root)
	state.completedAt = time.Now().UTC().Format(time.RFC3339)
	writeState(root, state)

	fmt.Println("\nHost preparation complete. VM state and every plane result are recorded in recipes/host-state.yaml.")
	fmt.Println("Manual fallback surfaces:")
	fmt.Println("  bash ./scripts/prerequisites.sh")
	fmt.Println("  bash ./scripts/agent-preflight.sh")
	fmt.Println("  bash ./scripts/install-observability.sh")
	fmt.Println("  ./policyctl validate")
	fmt.Println("If a package manager, agent, or optional integration is unavailable, the relevant capability is NOT_DEPLOYED rather than silently substituted.")
}

func newState() *setupState {
	return &setupState{
		startedAt:     time.Now().UTC().Format(time.RFC3339),
		foundation:    "PENDING",
		primary:       "PENDING",
		control:       "PENDING",
		observability: "PENDING",
		validation:    "PENDING",
		vmStatus:      "PENDING",
	}
}

func (s *setupState) stage(name, value string) {
	switch name {
	case "foundation":
		s.foundation = value
	case "primary_agent":
		s.primary = value
	case "control_learning":
		s.control = value
	case "observability_governance":
		s.observability = value
	case "validation":
		s.validation = value
	}
}

func writeState(root string, s *setupState) {
	osName, distro, version, kernel, arch, pkg := hostFacts()
	inventory := s.vmInventory
	if inventory == "" {
		inventory = "pending"
	}
	content := fmt.Sprintf(`schema: cusimanse.host-state/v1
run:
  id: %s
  started_at: %s
  completed_at: %s
  mode: interactive
host:
  os: %s
  distro: %s
  distro_version: %s
  kernel: %s
  architecture: %s
  package_manager: %s
planes:
  foundation:
    status: %s
    capabilities: [git, bash, curl, python3, ruby, go, qemu, lima]
  primary_agent:
    status: %s
    adapter: %s
  control_learning:
    status: %s
    capabilities: [jq, yq, sqlite, skills, retrieval, recipes]
  observability_governance:
    status: %s
    capabilities: [opentelemetry, phoenix, numbat, aegis, policyctl]
  validation:
    status: %s
    checks: [preflight, policy, recipe-contract, architecture]
vm:
  provider: lima-qemu
  status: %s
  runtime: limactl
  architecture: %s
  inventory: |
%s
evidence:
  state_file: recipes/host-state.yaml
  last_preflight: %s
`, safeID(s.startedAt), s.startedAt, s.completedAt, osName, distro, version, kernel, arch, pkg, s.foundation, s.primary, valueOr(s.adapter, "none"), s.control, s.observability, s.validation, s.vmStatus, arch, indentBlock(inventory, 4), time.Now().UTC().Format(time.RFC3339))
	_ = os.WriteFile(filepath.Join(root, statePath), []byte(content), 0644)
}

func discoverVM(root string) (string, string) {
	limactl, err := exec.LookPath("limactl")
	if err != nil {
		return "NOT_DEPLOYED", "limactl unavailable"
	}
	cmd := exec.Command(limactl, "list", "--format", "{{.Name}}|{{.Status}}|{{.Arch}}")
	cmd.Dir = root
	out, err := cmd.Output()
	if err != nil || strings.TrimSpace(string(out)) == "" {
		return "NO_VM_CREATED", "no Lima VMs currently exist"
	}
	return "DISCOVERED", strings.TrimSpace(string(out))
}

func indentBlock(v string, n int) string {
	pad := strings.Repeat(" ", n)
	lines := strings.Split(v, "\n")
	for i := range lines {
		lines[i] = pad + lines[i]
	}
	return strings.Join(lines, "\n")
}

func hostFacts() (string, string, string, string, string, string) {
	osName, arch := runtime.GOOS, runtime.GOARCH
	distro, version := "unknown", "unknown"
	if b, err := os.ReadFile("/etc/os-release"); err == nil {
		for _, line := range strings.Split(string(b), "\n") {
			if strings.HasPrefix(line, "ID=") {
				distro = strings.Trim(strings.TrimPrefix(line, "ID="), `"`)
			}
			if strings.HasPrefix(line, "VERSION_ID=") {
				version = strings.Trim(strings.TrimPrefix(line, "VERSION_ID="), `"`)
			}
		}
	}
	kernel := "unknown"
	if out, err := exec.Command("uname", "-sr").Output(); err == nil {
		kernel = strings.TrimSpace(string(out))
	}
	return osName, distro, version, kernel, arch, detectPackageManager()
}

func detectPackageManager() string {
	for _, p := range []string{"apt-get", "dnf", "pacman", "zypper", "apk", "brew", "pkg", "winget", "choco"} {
		if _, err := exec.LookPath(p); err == nil {
			return p
		}
	}
	return "none"
}

func valueOr(v, fallback string) string {
	if strings.TrimSpace(v) == "" {
		return fallback
	}
	return v
}

func safeID(v string) string {
	return strings.NewReplacer(":", "", "-", "", "+", "").Replace(v)
}

func chooseAdapter(r *bufio.Reader) string {
	fmt.Println("Primary agent (exactly one; optional):")
	fmt.Println("  goose, opencode, grok-build, antigravity, pi, hermes, codex")
	fmt.Println("  prime-intellect, claude-code, devin, none")
	fmt.Print("Selection (default none): ")
	v, _ := r.ReadString('\n')
	v = strings.ToLower(strings.TrimSpace(v))
	if v == "" {
		v = "none"
	}
	switch v {
	case "goose", "opencode", "grok-build", "antigravity", "pi", "hermes", "codex", "prime-intellect", "claude-code", "devin", "none":
		return v
	default:
		fail(fmt.Errorf("unsupported primary adapter %q", v))
		return "none"
	}
}

func findRoot() (string, error) {
	if v := os.Getenv("CUSIMANSE_ROOT"); v != "" {
		return filepath.Abs(v)
	}
	cwd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for p := cwd; ; p = filepath.Dir(p) {
		if _, err := os.Stat(filepath.Join(p, "go.mod")); err == nil {
			if _, err := os.Stat(filepath.Join(p, "cmd", "cusimanse-host", "main.go")); err == nil {
				return p, nil
			}
		}
		n := filepath.Dir(p)
		if n == p {
			break
		}
	}
	return "", fmt.Errorf("cannot locate Cusimanse repository root; run from checkout or set CUSIMANSE_ROOT")
}

func runningInWSL() bool {
	b, err := os.ReadFile("/proc/version")
	return err == nil && strings.Contains(strings.ToLower(string(b)), "microsoft")
}

func ask(r *bufio.Reader, prompt string, def bool) bool {
	fmt.Print(prompt)
	v, _ := r.ReadString('\n')
	v = strings.ToLower(strings.TrimSpace(v))
	if v == "" {
		return def
	}
	return v == "y" || v == "yes"
}

func runBash(root, rel string, env map[string]string) error {
	bash, err := exec.LookPath("bash")
	if err != nil {
		return fmt.Errorf("bash is required for repository scripts: %w", err)
	}
	cmd := exec.Command(bash, filepath.Join(root, rel))
	cmd.Dir = root
	cmd.Env = os.Environ()
	for k, v := range env {
		cmd.Env = append(cmd.Env, k+"="+v)
	}
	cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin
	return cmd.Run()
}

func runExec(root, program string, args ...string) error {
	cmd := exec.Command(program, args...)
	cmd.Dir = root
	cmd.Env = os.Environ()
	cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin
	return cmd.Run()
}

func buildPolicyctl(root string) {
	p := filepath.Join(root, "policyctl")
	if _, err := os.Stat(p); err == nil {
		return
	}
	fmt.Println("Building policyctl...")
	cmd := exec.Command("go", "build", "-o", p, "./cmd/policyctl")
	cmd.Dir = root
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	if err := cmd.Run(); err != nil {
		fail(fmt.Errorf("policyctl build failed: %w", err))
	}
}

func must(err error) {
	if err != nil {
		fail(err)
	}
}

func fail(err error) {
	fmt.Fprintf(os.Stderr, "Cusimanse setup failed: %v\n", err)
	os.Exit(1)
}
