package main

// Operation describes a supported operational surface. Helper is retained as
// a compatibility adapter name. Callers should depend on the operation name.
type Operation struct {
	Name      string
	Helper    string
	Native    bool
	Bootstrap bool
}

// Operations is the stable control-plane API for installation, validation,
// host readiness, testing, diagnostics and experiment helpers.
func Operations() []Operation {
	return []Operation{
		{Name: "install", Helper: "scripts/install.sh", Bootstrap: true},
		{Name: "validate", Helper: "native:validation", Native: true},
		{Name: "preflight", Helper: "native:preflight", Native: true},
		{Name: "test", Helper: "go test ./..."},
		{Name: "integration-test", Helper: "scripts/tests/integration.sh"},
		{Name: "tools", Helper: "scripts/tools.sh"},
		{Name: "session", Helper: "scripts/session.sh"},
		{Name: "policy", Helper: "native:policy", Native: true},
		{Name: "learning", Helper: "scripts/learningctl"},
		{Name: "observability", Helper: "scripts/observability.sh"},
		{Name: "run-experiment", Helper: "scripts/run-experiment.sh"},
	}
}
