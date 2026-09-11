package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/Opposum0112/ai-security-lab/pkg/lab"
)

const version = "0.3.0-dev"

func main() {
	if len(os.Args) < 2 {
		usage()
		return
	}

	switch os.Args[1] {
	case "version":
		fmt.Println("labctl", version)
	case "validate", "self-test":
		fs := flag.NewFlagSet(os.Args[1], flag.ExitOnError)
		root := fs.String("root", ".", "AI Security Lab project root")
		_ = fs.Parse(os.Args[2:])
		var err error
		if os.Args[1] == "validate" {
			err = lab.ValidateProject(*root)
		} else {
			err = lab.SelfTest(*root)
		}
		if err != nil {
			fmt.Fprintln(os.Stderr, "FAIL", err)
			os.Exit(2)
		}
		fmt.Println("PASS", os.Args[1])
	case "help", "--help", "-h":
		usage()
	default:
		fmt.Fprintf(os.Stderr, "unknown command %q\n", os.Args[1])
		usage()
		os.Exit(2)
	}
}

func usage() {
	fmt.Printf("labctl %s\n", version)
	fmt.Println("Deterministic Go control-plane bootstrap")
	fmt.Println()
	fmt.Println("Usage: labctl <command> [options]")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  validate   Validate the repository contract without executing workloads")
	fmt.Println("  self-test  Run deterministic Go control-plane checks")
	fmt.Println("  version    Print the labctl version")
	fmt.Println("  help       Show this help")
}
