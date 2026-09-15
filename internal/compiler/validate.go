package compiler

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

var (
	workloads = map[string]struct{}{
		"npm-install": {}, "npm-lifecycle": {}, "npm-threat": {}, "go-install": {},
	}
	networks = map[string]struct{}{
		"localhost-only": {}, "none": {}, "controlled": {},
	}
	rolesAllowed = map[string]struct{}{
		"operator": {}, "verifier": {}, "reporter": {},
	}
)

func Load(path string) (ExperimentDoc, error) {
	var doc ExperimentDoc
	b, err := os.ReadFile(path)
	if err != nil {
		return doc, err
	}
	if err := yaml.Unmarshal(b, &doc); err != nil {
		return doc, err
	}
	return doc, doc.Validate()
}

func LoadID(root, id string) (ExperimentDoc, error) {
	return Load(filepath.Join(root, "experiments", id+".yaml"))
}

func (d ExperimentDoc) Validate() error {
	if d.APIVersion != "cusimanse.dev/v1" {
		return fmt.Errorf("apiVersion must be cusimanse.dev/v1")
	}
	if d.Kind != "Experiment" {
		return fmt.Errorf("kind must be Experiment")
	}
	if d.Metadata.ID == "" || d.Metadata.Title == "" {
		return fmt.Errorf("metadata.id and title are required")
	}
	if d.Spec.Question == "" {
		return fmt.Errorf("spec.question is required")
	}
	if d.Spec.HostPrep != "default" && d.Spec.HostPrep != "none" {
		return fmt.Errorf("invalid hostPrep %q", d.Spec.HostPrep)
	}
	if len(d.Spec.Roles) == 0 {
		return fmt.Errorf("spec.roles is required")
	}
	for _, r := range d.Spec.Roles {
		if _, ok := rolesAllowed[r]; !ok {
			return fmt.Errorf("unknown role %q", r)
		}
	}
	if !contains(d.Spec.Scope.Exclude, "host-execution") {
		return fmt.Errorf("scope.exclude must include host-execution")
	}
	req := d.Spec.Requirements
	if req.Execution != "disposable" {
		return fmt.Errorf("execution must be disposable")
	}
	if req.OS != "linux" && req.OS != "macos" {
		return fmt.Errorf("invalid os %q", req.OS)
	}
	if _, ok := workloads[req.Workload]; !ok {
		return fmt.Errorf("unknown workload %q", req.Workload)
	}
	if _, ok := networks[req.Network]; !ok {
		return fmt.Errorf("unknown network %q", req.Network)
	}
	if len(req.Instrumentation) == 0 {
		return fmt.Errorf("instrumentation is required")
	}
	if len(d.Spec.PolicyChecks) == 0 {
		return fmt.Errorf("policyChecks is required")
	}
	if len(d.Spec.Acceptance) == 0 {
		return fmt.Errorf("acceptance is required")
	}
	if d.Spec.Operator != "goose" && d.Spec.Operator != "cli" {
		return fmt.Errorf("invalid operator %q", d.Spec.Operator)
	}
	return nil
}

func (d ExperimentDoc) Resolve() ResolveResult {
	return ResolveResult{
		ExperimentID: d.Metadata.ID,
		Workload:     d.Spec.Requirements.Workload,
		Handler:      d.Spec.Requirements.Workload,
		OS:           d.Spec.Requirements.OS,
		Execution:    d.Spec.Requirements.Execution,
		Network:      d.Spec.Requirements.Network,
		HostPrep:     d.Spec.HostPrep,
		Operator:     d.Spec.Operator,
	}
}

func contains(list []string, want string) bool {
	for _, item := range list {
		if item == want {
			return true
		}
	}
	return false
}
