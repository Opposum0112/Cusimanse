# Workload adapter contracts

Commit 10 defines narrow interfaces for shell, file, process, and npm workloads. These are contracts only: concrete host/VM implementations are injected later.

The npm contract accepts a working directory and optional argument list; it does not accept arbitrary recipe text or construct commands from untrusted strings.
