package main

import (
    "context"
    "errors"
    "fmt"
    "os"
    "os/exec"
    "path/filepath"
)

// The Go CLI exposes the operational entrypoints. scripts/install.sh remains
// the bootstrap adapter because the machine may not have Go before installation.
// Validation/preflight/tests remain auditable shell adapters until their logic is
// fully migrated to native Go checks with equivalent coverage.
func init() {
    if len(os.Args) < 2 { return }
    switch os.Args[1] {
    case "install": mustHandleCLICommand(handleInstall)
    case "validate": mustHandleCLICommand(func(root string) error { return runHelper(root, "scripts/tests/validate.sh") })
    case "preflight": mustHandleCLICommand(func(root string) error { return runHelper(root, "scripts/preflight.sh") })
    case "test": mustHandleCLICommand(func(root string) error { return runHelper(root, "scripts/tests/runtime.sh") })
    case "integration-test": mustHandleCLICommand(func(root string) error { return runHelper(root, "scripts/tests/integration.sh") })
    case "doctor": mustHandleCLICommand(func(root string) error { if err := runHelper(root, "scripts/tests/validate.sh"); err != nil { return err }; return runHelper(root, "scripts/preflight.sh") })
    case "observability": mustHandleCLICommand(func(root string) error { return runHelperArgs(root, "scripts/observability.sh", os.Args[2:]...) })
    }
}

func mustHandleCLICommand(handler func(string) error) {
    rootDir, err := commandRoot(os.Args[2:])
    if err != nil { fmt.Fprintln(os.Stderr, err); os.Exit(2) }
    if err := handler(rootDir); err != nil { fmt.Fprintf(os.Stderr, "cusimanse: %v\n", err); os.Exit(1) }
    os.Exit(0)
}

func commandRoot(args []string) (string, error) {
    if configured := os.Getenv("CUSIMANSE_ROOT"); configured != "" { st, err := os.Stat(configured); if err != nil || !st.IsDir() { return "", fmt.Errorf("CUSIMANSE_ROOT is not a directory: %s", configured) }; return configured, nil }
    for i := 0; i < len(args); i++ { if args[i] == "--root" && i+1 < len(args) { return filepath.Abs(args[i+1]) } }
    if wd, err := os.Getwd(); err == nil { if _, err := os.Stat(filepath.Join(wd, "recipes")); err == nil { return wd, nil } }
    return "", errors.New("repository root not found; run from the Cusimanse repository or set CUSIMANSE_ROOT")
}

func runHelper(root, rel string) error { return runHelperArgs(root, rel) }
func runHelperArgs(root, rel string, args ...string) error {
    path := filepath.Join(root, rel); st, err := os.Stat(path); if err != nil || st.IsDir() { return fmt.Errorf("helper unavailable: %s", path) }
    cmd := exec.CommandContext(context.Background(), path, args...); cmd.Dir, cmd.Stdout, cmd.Stderr, cmd.Stdin = root, os.Stdout, os.Stderr, os.Stdin
    return cmd.Run()
}

func handleInstall(root string) error {
    if _, err := os.Stat(filepath.Join(root, "scripts/install.sh")); err != nil { return fmt.Errorf("bootstrap installer missing: %w", err) }
    // A machine without Go must use the bootstrap script directly once; after
    // bootstrap, the Go CLI is the normal install/validate/preflight/test API.
    if _, err := exec.LookPath("go"); err != nil { return errors.New("Go is not installed; run scripts/install.sh once to bootstrap Go and host dependencies") }
    if err := runHelper(root, "scripts/install.sh"); err != nil { return fmt.Errorf("bootstrap installation failed: %w", err) }
    bin := filepath.Join(os.Getenv("HOME"), ".local", "bin", "cusimanse"); if custom := os.Getenv("CUSIMANSE_BIN"); custom != "" { bin = custom }
    if err := os.MkdirAll(filepath.Dir(bin), 0755); err != nil { return err }
    tmp := bin + ".tmp"; _ = os.Remove(tmp)
    cmd := exec.Command("go", "build", "-trimpath", "-o", tmp, "./cmd/cusimanse"); cmd.Dir, cmd.Stdout, cmd.Stderr = root, os.Stdout, os.Stderr
    if err := cmd.Run(); err != nil { return fmt.Errorf("build cusimanse: %w", err) }
    if err := os.Chmod(tmp, 0755); err != nil { _ = os.Remove(tmp); return err }
    if err := os.Rename(tmp, bin); err != nil { _ = os.Remove(tmp); return err }
    fmt.Printf("installed %s\n", bin); fmt.Println("set CUSIMANSE_ROOT to the repository root when invoking the installed binary")
    return nil
}
