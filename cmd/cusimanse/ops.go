package main

import (
    "context"
    "errors"
    "fmt"
    "os"
    "os/exec"
    "path/filepath"
)

// dispatchLifecycleCommands keeps installation/bootstrap concerns in the Go CLI
// while retaining shell helpers as small, auditable compatibility adapters.
// The first bootstrap still happens in scripts/install.sh because a machine may
// not have Go before installation starts.
func init() {
    if len(os.Args) < 2 {
        return
    }
    switch os.Args[1] {
    case "install":
        mustHandleCLICommand(handleInstall)
    case "validate":
        mustHandleCLICommand(func(root string) error { return runHelper(root, "scripts/tests/validate.sh") })
    case "preflight":
        mustHandleCLICommand(func(root string) error { return runHelper(root, "scripts/preflight.sh") })
    case "test":
        mustHandleCLICommand(func(root string) error { return runHelper(root, "scripts/tests/runtime.sh") })
    case "integration-test":
        mustHandleCLICommand(func(root string) error { return runHelper(root, "scripts/tests/integration.sh") })
    case "doctor":
        mustHandleCLICommand(func(root string) error {
            if err := runHelper(root, "scripts/tests/validate.sh"); err != nil { return err }
            return runHelper(root, "scripts/preflight.sh")
        })
    case "observability":
        mustHandleCLICommand(func(root string) error {
            args := os.Args[2:]
            return runHelperArgs(root, "scripts/observability.sh", args...)
        })
    }
}

func mustHandleCLICommand(handler func(string) error) {
    rootDir, err := commandRoot(os.Args[2:])
    if err != nil { fmt.Fprintln(os.Stderr, err); os.Exit(2) }
    if err := handler(rootDir); err != nil { fmt.Fprintf(os.Stderr, "cusimanse: %v\n", err); os.Exit(1) }
    os.Exit(0)
}

func commandRoot(args []string) (string, error) {
    if configured := os.Getenv("CUSIMANSE_ROOT"); configured != "" {
        if st, err := os.Stat(configured); err != nil || !st.IsDir() { return "", fmt.Errorf("CUSIMANSE_ROOT is not a directory: %s", configured) }
        return configured, nil
    }
    for i := 0; i < len(args); i++ {
        if args[i] == "--root" && i+1 < len(args) { return filepath.Abs(args[i+1]) }
    }
    if wd, err := os.Getwd(); err == nil {
        if _, err := os.Stat(filepath.Join(wd, "recipes")); err == nil { return wd, nil }
    }
    return "", errors.New("repository root not found; run from the Cusimanse repository or set CUSIMANSE_ROOT")
}

func runHelper(root, rel string) error { return runHelperArgs(root, rel) }

func runHelperArgs(root, rel string, args ...string) error {
    path := filepath.Join(root, rel)
    if st, err := os.Stat(path); err != nil || st.IsDir() { return fmt.Errorf("helper unavailable: %s", path) }
    ctx := context.Background()
    cmd := exec.CommandContext(ctx, path, args...)
    cmd.Dir = root
    cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin
    return cmd.Run()
}

func handleInstall(root string) error {
    if _, err := exec.LookPath("go"); err != nil { return errors.New("Go is required for the Go-managed installer; run scripts/install.sh once to bootstrap host dependencies and Go") }
    bin := filepath.Join(os.Getenv("HOME"), ".local", "bin", "cusimanse")
    if home := os.Getenv("CUSIMANSE_BIN"); home != "" { bin = home }
    if err := os.MkdirAll(filepath.Dir(bin), 0755); err != nil { return err }
    tmp := bin + ".tmp"
    _ = os.Remove(tmp)
    cmd := exec.Command("go", "build", "-trimpath", "-o", tmp, "./cmd/cusimanse")
    cmd.Dir = root
    cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
    if err := cmd.Run(); err != nil { return fmt.Errorf("build cusimanse: %w", err) }
    if err := os.Chmod(tmp, 0755); err != nil { _ = os.Remove(tmp); return err }
    if err := os.Rename(tmp, bin); err != nil { _ = os.Remove(tmp); return err }
    fmt.Printf("installed %s\n", bin)
    fmt.Println("runtime configuration: set CUSIMANSE_ROOT to the repository containing recipes/contracts")
    return nil
}
