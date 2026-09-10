# Hypothesis

Layered troubleshooting (host → QEMU → Lima → MCP → gateway) localizes failures faster than a full restart.

## Falsify if

- The target runs on the host instead of the documented execution plane.
- Evidence is missing, unhashed, or overwritten.
- A component is reported PASS when it was NOT_DEPLOYED.
