# Security Policy

Cusimanse is for authorized security research on systems, workloads and infrastructure controlled by the researcher.

## Required controls

1. Reference workloads execute only inside disposable Lima/QEMU VMs.
2. Do not provide unrelated host credentials, SSH keys, cloud tokens or personal files to workloads.
3. Keep model gateways and observability services bound to localhost unless remote access is explicitly required and reviewed.
4. Review privileged, destructive and network-sensitive actions before execution.
5. Preserve and hash evidence before destroying a VM.
6. Never commit secrets.

The contract and experiment recipe define the scope and workload for each experiment.

## Reporting a problem

Use GitHub's private security advisory mechanism for this repository or contact the repository owner. Do not publish credentials, private keys or sensitive forensic data in a public issue.

Include the affected path, commit, impact and a minimal reproduction where safe.

## Disclaimer

The software is provided "as is" under the MIT License. It is a research framework, not a guarantee that a host, VM, agent, gateway, model or third-party dependency is secure.
