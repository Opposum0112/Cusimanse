# npm-threat-001 contract

## Why
Exercise the security-research pipeline against a controlled npm package lifecycle behavior that resembles a supply-chain postinstall action.

## Scope
The workload runs only inside disposable Lima compute. The fixture writes a marker under `/tmp` and attempts a connection to `127.0.0.1:20128`. No external destination is authorized.

## Authorization and policy
This is a local, deterministic security-research fixture. Do not replace it with a public package, add credentials, contact external infrastructure, or execute it on the host.

Every run must validate `policies/host-policy.yaml` through the native Go policy engine before provisioning. The required controls are VM creation, network scope, credentials and host mounts. Denied actions are never bypassed. Approval-required actions require explicit researcher approval and an auditable decision recorded by the Go runtime.

The mount denylist (`policies/mount-denylist.yaml`) and permission tiers (`policies/permission-tiers.yaml`) are additional policy inputs. Policy is authoritative; shell wrappers are compatibility entrypoints only.

## Researcher/operator procedure

The researcher declares intent and approval; the operator/agent performs the controlled execution. Use the following sequence without inventing infrastructure:

```bash
./scripts/install.sh
cusimanse doctor
cusimanse validate
goose recipe validate recipes/npm-threat-001/recipe.yaml
cusimanse resolve npm-threat-001
cusimanse policy explain vm
cusimanse policy explain network
cusimanse policy check-all
cusimanse policy require vm --approved
cusimanse policy require network
cusimanse --approved run npm-threat-001 <session-id>
cusimanse observability report <session-id>
cusimanse policy audit
```

The adapter/operator must read this contract and the experiment requirements before using its own tools. Goose is the reference native operator. OpenCode, Hermes, Antigravity and Pi are handoff adapters and must not replace the Cusimanse capability boundary with host commands.

## Acceptance
A run is successful when:

1. the Goose recipe validates;
2. native Go policy validation succeeds;
3. required policy checks are recorded before VM provisioning;
4. the disposable VM is created before workload execution;
5. collectors start before the workload;
6. the postinstall marker is observed;
7. process/syscall/filesystem evidence is preserved and hashed;
8. the localhost connection attempt is observable when guest tooling permits it;
9. analysis and independent verification cite preserved evidence; and
10. the VM is destroyed before the session reaches COMPLETE.

The experiment is not evidence of real-world malware behavior and does not test agent escape, privilege escalation, external-network access, or host-policy bypass.
