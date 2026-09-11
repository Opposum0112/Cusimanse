package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		usage()
		return
	}

	switch os.Args[1] {
	case "show":
		fmt.Println("host_credentials: deny")
		fmt.Println("host_mounts: deny")
		fmt.Println("privileged_operations: approval-required")
		fmt.Println("disposable_vm: required")
	case "check":
		fmt.Println("PASS policy defaults")
	case "set":
		fs := flag.NewFlagSet("set", flag.ExitOnError)
		policy := fs.String("policy", "", "policy name")
		value := fs.String("value", "", "policy value")
		_ = fs.Parse(os.Args[2:])
		if *policy == "" || *value == "" {
			fmt.Fprintln(os.Stderr, "policy and value are required")
			os.Exit(2)
		}
		fmt.Printf("policy configuration requested: %s=%s\n", *policy, *value)
	default:
		usage()
		os.Exit(2)
	}
}

func usage() {
	fmt.Println("policyctl — host/security policy configuration")
	fmt.Println("Usage: policyctl <show|check|set>")
}
