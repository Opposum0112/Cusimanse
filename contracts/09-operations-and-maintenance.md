# Goose-native operations contract

## Operator
Goose is the only required workflow operator in this branch.

## Lifecycle

```text
prepare → validate recipe → run Goose → inspect evidence → verify → report → preserve
```

Use Goose's documented CLI and recipe validation commands. Keep the environment disposable when the research warrants isolation. Do not depend on a custom host daemon or orchestration service.

## Failure handling
Stop on missing authorization or unsafe environment configuration. Record incomplete experiments and do not fabricate evidence.
