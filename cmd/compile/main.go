package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/opposum0112/Cusimanse/internal/compiler"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintf(os.Stderr, "usage: compile validate|resolve|host-prep|execute <experiment-id> [--approved]\n")
		os.Exit(2)
	}
	cmd := os.Args[1]
	id := os.Args[2]
	root := "."
	if v := os.Getenv("CUSIMANSE_ROOT"); v != "" {
		root = v
	}
	doc, err := compiler.LoadID(root, id)
	if err != nil {
		fmt.Fprintf(os.Stderr, "compile: %v\n", err)
		os.Exit(1)
	}
	switch cmd {
	case "validate":
		fmt.Printf("valid %s\n", doc.Metadata.ID)
	case "resolve", "host-prep":
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		_ = enc.Encode(doc.Resolve())
	case "execute":
		approved := false
		for _, a := range os.Args[3:] {
			if a == "--approved" {
				approved = true
			}
		}
		if !approved {
			fmt.Fprintf(os.Stderr, "compile execute requires --approved\n")
			os.Exit(1)
		}
		fmt.Fprintf(os.Stderr, "compile execute: provision is delegated to existing cusimanse run for %s\n", id)
		fmt.Printf("approved execute plan for %s handler=%s\n", id, doc.Spec.Requirements.Workload)
	default:
		fmt.Fprintf(os.Stderr, "unknown command %s\n", cmd)
		os.Exit(2)
	}
}
