# Security Policy

Cusimanse is for authorized security research on systems, workloads and infrastructure controlled by the researcher.

## Required controls

1. Reference workloads execute only inside disposable isolated compute.
2. Do not provide unrelated host credentials, SSH keys, cloud tokens or personal files to workloads.
3. Keep model gateways and observability services bound to localhost unless remote access is explicitly required and reviewed.
4. Review privileged, destructive and network-sensitive actions before execution.
5. Preserve and hash evidence before destroying a sandbox.
6. Never commit secrets.

Contracts, recipes, policy and provider configuration define the declared scope for each experiment.

## Reporting a vulnerability

Use GitHub's private security advisory mechanism for this repository or contact the repository owner. Do not publish credentials, private keys or sensitive forensic data in a public issue.

Include the affected path, commit, impact and a minimal reproduction where safe.

## Isolation disclaimer

Cusimanse provides policy and sandbox boundaries, but no software can guarantee perfect isolation from every host, hypervisor, kernel, dependency, provider or workload vulnerability. Treat experimental workloads as untrusted and use dedicated research infrastructure for high-risk testing.

The project is provided "as is" under the Apache License 2.0.
