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
    root, err := findRoot(); if err != nil { fail(err) }
    if runtime.GOOS == "windows" && !runningInWSL() { fmt.Println("Cusimanse uses WSL2 for the Linux Lima/QEMU execution path. Clone and run the repository inside WSL2."); os.Exit(2) }
    r := bufio.NewReader(os.Stdin)
    fmt.Println("Cusimanse interactive researcher host preparation")
    fmt.Printf("Host: %s/%s\nRepository: %s\n", runtime.GOOS, runtime.GOARCH, root)
    fmt.Println("One Go front door installs and checks each plane in order. Manual commands are printed separately at the end.")

    if ask(r, "1. Install/repair Host + VM plane? [Y/n]: ", true) { must(runBash(root, "scripts/prerequisites.sh", map[string]string{"CUSIMANSE_PROFILE":"1"})) }

    adapter := chooseAdapter(r)
    if adapter != "none" && ask(r, "2. Install all supported Primary Agent adapters? [Y/n]: ", true) {
        must(runBash(root, "scripts/prerequisites.sh", map[string]string{"CUSIMANSE_PROFILE":"1", "CUSIMANSE_INSTALL_AGENTS":"1"}))
    }
    if adapter != "none" { must(runBash(root, "scripts/configure-recipes.sh", map[string]string{"CUSIMANSE_PRIMARY_ADAPTER":adapter})) }

    if ask(r, "3. Install Control + Learning plane? [Y/n]: ", true) { must(runBash(root, "scripts/prerequisites.sh", map[string]string{"CUSIMANSE_PROFILE":"2"})) }

    if ask(r, "4. Install Observability + Governance plane (Numbat + Aegis + OTEL/Phoenix)? [Y/n]: ", true) {
        must(runBash(root, "scripts/prerequisites.sh", map[string]string{"CUSIMANSE_PROFILE":"3"}))
        must(runBash(root, "scripts/install-observability.sh", nil))
        must(runBash(root, "scripts/configure-recipes.sh", map[string]string{"CUSIMANSE_OBSERVABILITY_STATUS":"CONFIGURED"}))
    }

    fmt.Println("\n5. Running comprehensive Go-driven flight-check...")
    must(runBash(root, "scripts/agent-preflight.sh", map[string]string{"CUSIMANSE_PRIMARY_ADAPTER":adapter}))
    buildPolicyctl(root)
    if ask(r, "Run policy validation now? [Y/n]: ", true) { must(runExec(root, filepath.Join(root, "policyctl"), "validate")) }
    fmt.Println("\nHost preparation complete. Review recipe changes before committing them to your research branch.")
    fmt.Println("Manual options (optional):")
    fmt.Println("  bash ./scripts/prerequisites.sh")
    fmt.Println("  bash ./scripts/agent-preflight.sh")
    fmt.Println("  bash ./scripts/install-observability.sh")
    fmt.Println("  ./policyctl validate")
}

func chooseAdapter(r *bufio.Reader) string {
    fmt.Print("Primary agent [prime-agent/hermes/goose/none] (default prime-agent): ")
    v, _ := r.ReadString('\n'); v = strings.ToLower(strings.TrimSpace(v)); if v == "" { v = "prime-agent" }
    switch v { case "prime-agent", "hermes", "goose", "none": return v; default: fail(fmt.Errorf("unsupported primary adapter %q", v)); return "none" }
}
func findRoot() (string,error) { if v:=os.Getenv("CUSIMANSE_ROOT"); v!="" { return filepath.Abs(v) }; cwd,e:=os.Getwd(); if e!=nil{return "",e}; for p:=cwd;;p=filepath.Dir(p){ if _,e:=os.Stat(filepath.Join(p,"go.mod"));e==nil { if _,e:=os.Stat(filepath.Join(p,"cmd","cusimanse-host","main.go"));e==nil{return p,nil} }; n:=filepath.Dir(p);if n==p{break} };return "",fmt.Errorf("cannot locate Cusimanse repository root; run from checkout or set CUSIMANSE_ROOT") }
func runningInWSL() bool { b,e:=os.ReadFile("/proc/version");return e==nil&&strings.Contains(strings.ToLower(string(b)),"microsoft") }
func ask(r *bufio.Reader,p string,def bool) bool {fmt.Print(p);v,_:=r.ReadString('\n');v=strings.ToLower(strings.TrimSpace(v));if v==""{return def};return v=="y"||v=="yes"}
func runBash(root,rel string,env map[string]string) error { bash,e:=exec.LookPath("bash");if e!=nil{return fmt.Errorf("bash is required: %w",e)};cmd:=exec.Command(bash,filepath.Join(root,rel));cmd.Dir=root;cmd.Env=os.Environ();for k,v:=range env{cmd.Env=append(cmd.Env,k+"="+v)};cmd.Stdout,cmd.Stderr,cmd.Stdin=os.Stdout,os.Stderr,os.Stdin;return cmd.Run() }
func runExec(root,program string,args ...string) error {cmd:=exec.Command(program,args...);cmd.Dir=root;cmd.Env=os.Environ();cmd.Stdout,cmd.Stderr,cmd.Stdin=os.Stdout,os.Stderr,os.Stdin;return cmd.Run()}
func buildPolicyctl(root string){p:=filepath.Join(root,"policyctl");if _,e:=os.Stat(p);e==nil{return};fmt.Println("Building policyctl...");cmd:=exec.Command("go","build","-o",p,"./cmd/policyctl");cmd.Dir=root;cmd.Stdout,cmd.Stderr=os.Stdout,os.Stderr;if e:=cmd.Run();e!=nil{fail(fmt.Errorf("policyctl build failed: %w",e))}}
func must(e error){if e!=nil{fail(e)}}
func fail(e error){fmt.Fprintf(os.Stderr,"Cusimanse setup failed: %v\n",e);os.Exit(1)}
