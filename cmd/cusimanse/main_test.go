package main

import "testing"

func TestContainsAll(t *testing.T) {
	if !containsAll([]string{"process", "syscall", "filesystem"}, []string{"process", "filesystem"}) { t.Fatal("expected capability set to match") }
	if containsAll([]string{"process"}, []string{"process", "network"}) { t.Fatal("expected missing capability to fail") }
}

func TestWorkloadRequirementsMatch(t *testing.T) {
	w := WorkloadProfile{Requirements: Requirements{Execution: "disposable", OS: "linux", Workload: "npm", Network: "localhost-only", Instrumentation: []string{"process", "syscall", "filesystem", "network"}}}
	if !matches(Requirements{Execution: "disposable", OS: "linux", Workload: "npm", Network: "localhost-only", Instrumentation: []string{"process", "network"}}, w) { t.Fatal("expected workload requirements to match") }
	if matches(Requirements{Execution: "disposable", OS: "linux", Workload: "npm", Network: "controlled"}, w) { t.Fatal("expected network mismatch") }
}
