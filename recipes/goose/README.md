# Goose project

`recipes/goose/project.yaml` is the entry recipe. Goose reads it and composes the modular recipe families under `recipes/`.

Goose is the project's orchestrator, operator and executor. There is no competing project controller. `policyctl` is the separate host/security policy configuration CLI.

The intended workflow is:

`discover -> validate -> preflight -> plan -> review -> bootstrap -> provision -> instrument -> execute -> collect -> forensic -> verify -> report -> tokens -> destroy`

Use the modular recipes to change the project without changing the agentic operator:

- experiments
- workloads
- installation
- host profiles
- VM profiles
- tools
- instrumentation
- agent monitoring
- agent roles
- orchestration
- routing
- stages
- reporting
- token dashboard
