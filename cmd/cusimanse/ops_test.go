package main

import (
    "os"
    "path/filepath"
    "testing"
)

func TestCommandRootUsesEnvironment(t *testing.T) {
    t.Setenv("CUSIMANSE_ROOT", t.TempDir())
    got, err := commandRoot(nil)
    if err != nil { t.Fatal(err) }
    want, _ := filepath.Abs(os.Getenv("CUSIMANSE_ROOT"))
    if got != want { t.Fatalf("root=%q want=%q", got, want) }
}

func TestCommandRootRejectsMissingRoot(t *testing.T) {
    t.Setenv("CUSIMANSE_ROOT", filepath.Join(t.TempDir(), "missing"))
    if _, err := commandRoot(nil); err == nil { t.Fatal("expected missing root error") }
}
