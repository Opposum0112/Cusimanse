# 10 — Validation and Acceptance

## Level 1 — Host

- [ ] architecture is x86_64
- [ ] adequate RAM
- [ ] adequate disk
- [ ] QEMU installed
- [ ] Lima installed
- [ ] virtualization capability verified

## Level 2 — Execution

- [ ] minimal Lima VM boots
- [ ] network works
- [ ] VM can be destroyed
- [ ] evidence can be exported

## Level 3 — Agent

- [ ] Antigravity CLI works
- [ ] at least one additional harness works
- [ ] custom agent configuration loads
- [ ] MCP works
- [ ] permissions work
- [ ] skills load

## Level 4 — Security

- [ ] Aegis policy works
- [ ] Numbat records events
- [ ] privileged actions are controlled
- [ ] no credentials are exposed

## Level 5 — Model

- [ ] gateway works
- [ ] logical aliases work
- [ ] token/latency logging works
- [ ] fallback behavior is understood

## Level 6 — Observability

- [ ] OTel works
- [ ] OpenInference traces work where supported
- [ ] Phoenix receives traces
- [ ] runtime evidence is collected

## Level 7 — Experiment

- [ ] go-install-001 executes
- [ ] evidence is captured
- [ ] evidence is reduced
- [ ] findings are generated
- [ ] findings are independently verified
- [ ] report generated
- [ ] integration scorecard generated
- [ ] Git commit created

## Acceptance states

### PASS
All required controls and workflow stages operate.

### PARTIAL
The platform works but one or more optional components are unavailable.

### FAIL
A mandatory safety or reproducibility boundary is broken.

### NOT DEPLOYED
The component has not yet been installed and must not be represented as exercised.
