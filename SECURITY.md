# Security Policy

## Scope

This repository describes a **personal, isolated AI security research lab**.
It is intended for studying agent tooling, model routing, and telemetry on
hardware and virtual machines you control.

It is **not** an invitation to test other people's systems.

## Lab rules

1. Untrusted experiments run only in disposable Lima/QEMU VMs.
2. Host credentials, SSH keys, cloud tokens, and personal files stay off the VM.
3. Management services bind to `127.0.0.1` unless remote access is explicitly required.
4. Privileged MCP operations require approval.
5. Evidence is hashed and preserved before a VM is deleted.
6. Secrets never go into Git.

See [AGENTS.md](AGENTS.md) and [04-security-model.md](04-security-model.md).

## Reporting a problem in this repository

If you find a credential, unsafe default, or documentation error in this
project, open a **private** GitHub security advisory on
[Opposum0112/ai-security-lab](https://github.com/Opposum0112/ai-security-lab)
or contact the repository owner. Do not file a public issue that contains
secrets.

Please include:

- the file path and commit
- what is exposed or unsafe
- a suggested fix if you have one

## Supported versions

This package is a living lab baseline. Treat the default branch as current.
There is no long-term support channel.

## Disclaimer

The software and documents are provided "as is" under the MIT License.
Using them against systems you do not own or have permission to test is
outside the intended use of this project.
