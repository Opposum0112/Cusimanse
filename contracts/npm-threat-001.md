# npm-threat-001 contract

## Why
Exercise the security-research pipeline against a controlled npm package lifecycle behavior that resembles a supply-chain postinstall action.

## Scope
The workload runs only inside the disposable Lima guest. The fixture writes a marker under `/tmp` and attempts a connection to `127.0.0.1:20128`. No external destination is authorized.

## Authorization
This is a local, deterministic security-research fixture. Do not replace it with a public package, add credentials, contact external infrastructure, or execute it on the host.

## Acceptance
A run is successful when:

1. the Goose recipe validates;
2. the disposable VM is created before workload execution;
3. collectors start before the workload;
4. the postinstall marker is observed;
5. process/syscall/filesystem evidence is preserved and hashed;
6. the localhost connection attempt is observable when the guest tooling permits it;
7. analysis and independent verification cite preserved evidence; and
8. the VM is destroyed before the session reaches COMPLETE.

The experiment is not evidence of real-world malware behavior and does not test agent escape, privilege escalation, or external-network access.
