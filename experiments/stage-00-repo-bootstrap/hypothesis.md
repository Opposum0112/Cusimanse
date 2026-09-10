# Hypothesis

labctl init produces a complete, hashed layout without secrets.

## Falsify if

- The target runs on the host instead of the documented execution plane.
- Evidence is missing, unhashed, or overwritten.
- A component is reported PASS when it was NOT_DEPLOYED.
