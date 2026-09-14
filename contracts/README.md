# Cusimanse Research Contracts

Contracts define the human research agreement around a Goose workflow: research question, authorization, scope, safety expectations, evidence requirements and acceptance criteria.

The executable workflow is a Goose YAML recipe. Contracts do not define a second orchestration system, VM controller, gateway or telemetry service.

Recommended flow:

```text
Contract → Goose recipe → Goose session → evidence → verification → report
```

See the official Goose recipe documentation for the executable recipe schema and validation rules.
