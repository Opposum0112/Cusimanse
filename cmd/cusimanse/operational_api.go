package main

// Operation describes a supported operational surface. Helper is retained as
// an implementation adapter until that operation has equivalent native-Go
// coverage; callers should depend on the operation name, not the script path.
type Operation struct {
    Name   string
    Helper string
    Native bool
    Bootstrap bool
}

// Operations is the stable, discoverable control-plane API for installation,
// validation, host readiness, testing, diagnostics and experiment helpers.
func Operations() []Operation {
    return []Operation{
        {Name: "install", Helper: "scripts/install.sh", Bootstrap: true},
        {Name: "validate", Helper: "scripts/tests/validate.sh"},
        {Name: "preflight", Helper: "scripts/preflight.sh"},
        {Name: "test", Helper: "scripts/tests/runtime.sh"},
        {Name: "integration-test", Helper: "scripts/tests/integration.sh"},
        {Name: "tools", Helper: "scripts/tools.sh"},
        {Name: "session", Helper: "scripts/session.sh"},
        {Name: "policy", Helper: "scripts/policyctl"},
        {Name: "learning", Helper: "scripts/learningctl"},
        {Name: "observability", Helper: "scripts/observability.sh"},
        {Name: "run-experiment", Helper: "scripts/run-experiment.sh"},
    }
}
