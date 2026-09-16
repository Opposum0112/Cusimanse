# Operator ABI

The Operator ABI is the stable boundary between an external agent/harness and Cusimanse. It exposes typed JSON-RPC 2.0 plus REST/SSE over HTTP; the agent never receives unrestricted host execution access.

## JSON-RPC

`POST /rpc`

Methods:

- `experiment.run` — compile a recipe, resolve a compute provider and runtime, execute in the sandbox, and return run telemetry/artifact references.
- `evidence.inspect` — inspect evidence/telemetry for a run.
- `skills.promote` — validate a candidate skill and move it to the validated lifecycle stage.
- `providers.list` — report detected provider availability.

Unknown methods return JSON-RPC `-32601`. Execution failures are returned as `-32000` errors.

## REST/SSE

- `POST /v1/experiments/run`
- `GET /v1/experiments/:runId/events` — SSE event stream
- `GET /v1/evidence/:runId`
- `POST /v1/skills/promote`
- `GET /v1/providers`

## Security model

Tool inputs are declarative. A policy evaluation occurs before compute execution. Missing policy matches are denied. Compute providers must preserve argument boundaries and must not interpolate untrusted input into a shell command.
