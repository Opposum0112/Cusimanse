# Hypothesis

Privileged operations (sudo, host mounts, credentials) default to deny.

## Falsify if

- The target runs on the host instead of the documented execution plane.
- Evidence is missing, unhashed, or overwritten.
- A component is reported PASS when it was NOT_DEPLOYED.
