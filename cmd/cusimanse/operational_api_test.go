package main

import "testing"

func TestOperationsExposeAllHelperSurfaces(t *testing.T) {
    want := map[string]bool{
        "install": true, "validate": true, "preflight": true,
        "test": true, "integration-test": true, "tools": true,
        "session": true, "policy": true, "learning": true,
        "observability": true, "run-experiment": true,
    }
    got := Operations()
    for _, op := range got {
        if !want[op.Name] { t.Fatalf("unexpected operation %q", op.Name) }
        delete(want, op.Name)
        if op.Helper == "" { t.Fatalf("operation %q has no compatibility adapter", op.Name) }
    }
    for name := range want { t.Fatalf("operation %q is not exposed", name) }
}

func TestCommandRootUsesConfiguredRoot(t *testing.T) {
    t.Setenv("CUSIMANSE_ROOT", t.TempDir())
    root, err := commandRoot(nil)
    if err != nil { t.Fatal(err) }
    if root == "" { t.Fatal("expected configured root") }
}
