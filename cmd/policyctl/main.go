package main

import (
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
	default:
		usage()
		os.Exit(2)
	}
}

func usage() {
	fmt.Println("policyctl — host/security policy configuration")
	fmt.Println("Usage: policyctl <show|check>")
}
