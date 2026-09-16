# Security Policy

Cusimanse is intended for authorized security research on systems, workloads, and infrastructure controlled by the researcher.

## Supported versions

Security fixes are developed against the current `harness-neutral-runtime` line and the latest published release. Older releases may receive fixes only when the maintainer explicitly marks them supported.

## Security boundary

Cusimanse treats the operator ABI, policy engine, compute-provider SPI, execution runtime, and evidence lifecycle as security boundaries. Tool proposals are denied when policy cannot establish an explicit allow decision.

Host isolation is defense-in-depth, not a cryptographic or absolute guarantee. Lima, Multipass, Firecracker/cloud adapters, the host kernel, hypervisor, container runtime, and guest workload each remain part of the trusted-computing and threat model.

## Hypervisor breakout classifications

- **Critical:** confirmed or plausibly reproducible guest-to-host escape, arbitrary host code execution, or cross-sandbox compromise.
- **High:** host filesystem/credential access or privilege boundary bypass without demonstrated full code execution.
- **Medium:** isolation weakening, unsafe mount/network defaults, or policy bypass requiring meaningful preconditions.
- **Low:** information disclosure or hardening gaps without a demonstrated isolation bypass.

## Host isolation guarantees and limitations

The runtime guarantees that declared tool execution is routed through a selected `ComputeProvider` and that policy-denied operations are not intentionally dispatched by Cusimanse. Providers must use argument-vector subprocess APIs rather than shell interpolation. The project does **not** guarantee protection against a vulnerable hypervisor, host kernel, provider CLI, malicious host mounts, or compromised dependencies.

For high-risk malware or exploit research, use a dedicated research host and minimize host mounts, credentials, and network reachability.

## Reporting a vulnerability

Use GitHub's private security advisory mechanism for this repository or contact the repository owner. Do not publish credentials, private keys, exploit payloads that materially enable host compromise, or sensitive forensic data in a public issue.

Include the affected path, commit, impact, reproduction steps, and relevant logs where safe.

Never commit secrets to the repository.
