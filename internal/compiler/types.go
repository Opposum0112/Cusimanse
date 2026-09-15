package compiler

type ExperimentDoc struct {
	APIVersion string   `yaml:"apiVersion"`
	Kind       string   `yaml:"kind"`
	Metadata   Metadata `yaml:"metadata"`
	Spec       Spec     `yaml:"spec"`
}

type Metadata struct {
	ID    string `yaml:"id"`
	Title string `yaml:"title"`
}

type Spec struct {
	Question      string         `yaml:"question"`
	HostPrep      string         `yaml:"hostPrep"`
	Roles         []string       `yaml:"roles"`
	Scope         Scope          `yaml:"scope"`
	Requirements  Requirements   `yaml:"requirements"`
	PolicyChecks  []string       `yaml:"policyChecks"`
	Acceptance    []string       `yaml:"acceptance"`
	Operator      string         `yaml:"operator"`
	Observability Observability  `yaml:"observability"`
}

type Scope struct {
	Include []string `yaml:"include"`
	Exclude []string `yaml:"exclude"`
}

type Requirements struct {
	Execution       string   `yaml:"execution"`
	OS              string   `yaml:"os"`
	Workload        string   `yaml:"workload"`
	Network         string   `yaml:"network"`
	Instrumentation []string `yaml:"instrumentation"`
}

type Observability struct {
	Host       []string `yaml:"host"`
	Experiment []string `yaml:"experiment"`
}

type ResolveResult struct {
	ExperimentID string `json:"experimentId"`
	Workload     string `json:"workload"`
	Handler      string `json:"handler"`
	OS           string `json:"os"`
	Execution    string `json:"execution"`
	Network      string `json:"network"`
	HostPrep     string `json:"hostPrep"`
	Operator     string `json:"operator"`
}
